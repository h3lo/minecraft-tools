#!/bin/bash

svrInstance=$1

function server_say {
  /usr/bin/screen -p 0 -S mc-${svrInstance} -X eval 'stuff ""\015'
}

tail -Fn0 /opt/minecraft/${svrInstance}/logs/latest.log | \
  while read line ; do
    if [[ ${line} =~ 'joined the game' ]]; then
      /usr/bin/screen -p 0 -S mc-${svrInstance} -X eval 'stuff "say Welcome."\015'
      if [[ ${line} =~ 'braindrp' ]] || [[ ${line} =~ 'Black_Reggie' ]] || [[ ${line} =~ 'Free_Stalker' ]]; then
        continue
      fi
      sleep 2
      if [[ ${svrInstance} =~ 'skyblock' ]]; then
        continue
      fi
      /usr/bin/screen -p 0 -S mc-${svrInstance} -X eval 'stuff "say 1. No griefing or stealing."\015'
      /usr/bin/screen -p 0 -S mc-${svrInstance} -X eval 'stuff "say 2. Keep your distance. Respect other peoples bases and do not build in or too close to them (minimum 100 block buffer)."\015'
      /usr/bin/screen -p 0 -S mc-${svrInstance} -X eval 'stuff "say 3. No cheating! No plugins or other enhancements."\015'
      /usr/bin/screen -p 0 -S mc-${svrInstance} -X eval 'stuff "say 4. Don'"'"'t be a dick; do unto others etc."\015'
      /usr/bin/screen -p 0 -S mc-${svrInstance} -X eval 'stuff "say 5. If you see blocks that are in any way valuable and they have a torch on them, they have been claimed. Do not take them."\015'
      #elif [[ ${line} =~ 'was slain by ' ]]; then
      #/usr/bin/screen -p 0 -S mc-${svrInstance} -X eval 'stuff "say '$(echo ${line} | sed 's///')' suckkkkkkkkkkkkkkkkks"\015'
    elif [[ ${line} =~ ^\[..\:..\:..\]\ \[Server\ thread\/INFO\]\:\ Done\ \(.*\)!\ For\ help,\ type\ \"help\" ]]; then
      sleep 2
      /usr/bin/screen -p 0 -S mc-${svrInstance} -X eval 'stuff "difficulty"\015'
    elif [[ ${line} =~ ^\[..\:..\:..\]\ \[Server\ thread\/INFO\]\:\ 'The difficulty is Peaceful' ]]; then
      /usr/bin/screen -p 0 -S mc-${svrInstance} -X eval 'stuff "difficulty normal"\015'
    fi
  done

#  awk '/stragonious / { print | "echo" }'
