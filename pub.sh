#!/bin/sh

mosquitto_pub -h localhost -p 1883 -t temperature -u admin -P admin -m "teste;123"

