#!/bin/bash

###############################################################
BASEDIR=$(dirname "$BASH_SOURCE")
. $BASEDIR/server.conf
###############################################################


main() {
    local var now=$(date +"%Y-%m-%d %T")
    echo "Servidor MQTT - "$now
    echo "By Wesley & Giovanni"
    echo "-----------------------------------"
    { 
        receive "temperature"
    }&{ 
        receive "luminosity" 
    }&{
        send "temperature"
    }&{
        send "luminosity"
    }
}
###############################################################
receive(){
    local var type=$1

    echo "Recebendo "$type
    
    create_table $type
    
    local var cmd="mosquitto_sub -h localhost -p 1883 -t "$1" -u admin -P admin"
    $cmd | { # redirect output to background
        while IFS= read -r line # read line by line
        do
            process $type $line
        done
    }
}
###############################################################
create_table(){
    local var type=$1

    local var query="CREATE TABLE IF NOT EXISTS \
                "$type"_data ( \
                    SENSOR_ID VARCHAR(64), \
                    DATE_TIME DATETIME, \
                    VALUE DOUBLE \
                )"

    sudo mysql --defaults-file=$BASEDIR/sql.ini -e "$query" teste
}
###############################################################
insert_value(){
    local var type=$1
    local var sensor_id=$2
    local var date_time=$3
    local var value=$4
          
    local var query="INSERT INTO "$type"_data \
            VALUES ( \
                '"$sensor_id"', \
                '"$date_time"', \
                "$value" \
            )"
                    
    sudo mysql --defaults-file=$BASEDIR/sql.ini -e "$query" teste
}
###############################################################
process(){
    local var type=$1
    local var fields=(${2//;/ }) # split into array
    
    echo "* Recebido = "$2
    
    local var id=${fields[0]}
    local var value=${fields[1]}
    
    if [ -f "sensor_list" ]; then
        local var exists=$(grep -m1 -Fx "$id" sensor_list) # find single line for exact match
        if [ -z "$exists" ]; then # check if variable is empty
            echo "sensor "$id" not found"
            return
        fi
    fi
    
    local var now=$(date +"%Y-%m-%d %T")
    #echo $id';'$value';'$now >> $type'_log' # append to file
    insert_value "$type" "$id" "$now" "$value"
}
###############################################################
send(){
    local var type=$1
    
    echo "Enviando "$type

    local var last_action
    for (( ; ; ))
    do
        if [ -f $type"_log" ]; then
            local var query="SELECT \
                                CAST( VALUE AS INT ) \
                            FROM \
                                "$type"_data \
                            ORDER BY  \
                                DATE_TIME DESC \
                            LIMIT 1"
                            
            local var value=$(sudo mysql --defaults-file=$BASEDIR/sql.ini -N -e "$query" teste)

            local var min_var=$type"_min"
            local var max_var=$type"_max"
            
            local var action="inactivate"
            if [ $value -lt ${!min_var} ] || [ $value -gt ${!max_var} ]; then
                action="activate"
            fi
            
            if [ "$last_action" != "$action" ]; then
                mosquitto_pub -h localhost -p 1883 -t action -u admin -P admin -m $action
                last_action=$action
            fi
        fi
        sleep 10
    done
}
###############################################################
main "$@"
###############################################################
