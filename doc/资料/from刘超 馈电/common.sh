####################################
# VERSION = 1.1.8
# HARDWARE = TFT 1.1.8
####################################


#!/bin/bash
#set -x
CMD_TYPE=""
CMD_CODE=""
APP_COMMON_PATH=""
APP_WORKSPACE_DIR=""

DRIVE_PATH="/nvme/nvme0n1p1"

usage()
{
	progName=$(basename $0)
	cat <<EOF
	common.sh version v0.0.1test
	Usage:
	$progName <type> <code> ...
	type=01H -- Ethernet command
		
	type=02H -- CAN-Bus command
		
EOF
}

info_log()
{
	echo $1 >> common.log
}

error_log()
{
	echo $1 >&2 2>> common.log
}

tmrSelect()
{
	local filePath="$1"
	local fileDir="$(dirname "$(realpath "$filePath")")"
	local fileName="$(basename "$filePath")"

	if [ ! -d "$fileDir/.tmr" ]; then
		error_log "$fileDir/.tmr does not exist!"
		return 1
	fi

	if ! ([ -f "$fileDir/.tmr/$fileName.1" ] && \
	  [ -f "$fileDir/.tmr/$fileName.2" ] && \
	  [ -f "$fileDir/.tmr/$fileName.3" ]); then
		error_log "tmr file invalid!"
		return 1
	fi

	if ! ([ -f "$fileDir/.tmr/$fileName.1.md5" ] && \
	  [ -f "$fileDir/.tmr/$fileName.2.md5" ] && \
	  [ -f "$fileDir/.tmr/$fileName.3.md5" ]); then
		error_log "md5 file invalid!"
		return 1
	fi

	# Check md5
	local matchedCount=0
	local matchedFilePath=""
	local corruptedFilePath=""
	for i in 1 2 3
	do
		local savedMd5Hash="$(cat "$fileDir/.tmr/$fileName.$i.md5")"
		local calcMd5Hash="$(md5sum "$fileDir/.tmr/$fileName.$i" | awk 'NR==1 {print $1}')"
		if [ "$savedMd5Hash" == "$calcMd5Hash" ]; then
			let matchedCount++
			matchedFilePath="$fileDir/.tmr/$fileName.$i"
		else
			# Mark unmatched file as corrupted file
			corruptedFilePath="$fileDir/.tmr/$fileName.$i"
		fi
	done

	# Choose 2 of 3
	if [ $matchedCount -lt 2 ]; then
		error_log "tmr select failed!"
		return 1
	fi

	# Hard link matched file
	ln -f "$matchedFilePath" "$filePath"

	# Recover corrupted file
	if [ ! -z "$corruptedFilePath" ]; then
		cp -f "$matchedFilePath" "$corruptedFilePath" > /dev/null
		cp -f "$matchedFilePath.md5" "$corruptedFilePath.md5" > /dev/null
	fi

	echo "$filePath"
}

tmrSave()
{
	local filePath="$1"
	local fileDir="$(dirname "$(realpath "$filePath")")"
	local fileName="$(basename "$filePath")"

	if [ ! -d "$fileDir/.tmr" ]; then
		mkdir -p "$fileDir/.tmr"
	fi

	local md5Hash="$(md5sum "$filePath" | awk 'NR==1 {print $1}')"
	cp -f "$filePath" "$fileDir/.tmr/$fileName.1"
	cp -f "$filePath" "$fileDir/.tmr/$fileName.2"
	cp -f "$filePath" "$fileDir/.tmr/$fileName.3"

	echo "$md5Hash" > "$fileDir/.tmr/$fileName.1.md5"
	echo "$md5Hash" > "$fileDir/.tmr/$fileName.2.md5"
	echo "$md5Hash" > "$fileDir/.tmr/$fileName.3.md5"

	# Create hard link
	ln -f "$fileDir/.tmr/$fileName.1" "$filePath"

	echo "$filePath"
}

tmrSaveAppCommonScript()
{
	local vendor=$1
	local appId=$2
	local filePath=$3
	local targetScriptDir="/$DRIVE_PATH/comm/app/$vendor/$appId/"
  rm -rf "$targetScriptDir"

	if [ ! -d "$targetScriptDir" ]; then
		mkdir -p "$targetScriptDir" > /dev/null
	fi

	cp -f "$filePath" "$targetScriptDir" > /dev/null

	local fileName="$(basename "$filePath")"
	local targetScriptPath="$targetScriptDir/$fileName"

	APP_COMMON_PATH="$(tmrSave "$targetScriptPath")"
}

checkVendorAndAppIdLen()
{
	local vendor=$1
	local appId=$2
	local vendorLen=${#vendor}
	local appIdLen=${#appId}

	if [ $vendorLen -ne 2 ] || [ $appIdLen -ne 3 ]; then
		error_log "Vendor length or appId length illegal!"
		return 1
	fi
}

softwareVersionQuery()
{
	if [ $# -ne 4 ]; then
		error_log "$@ command invalid!"
		return 1
	fi

	local vendor=$3
	local appId=$4

	APP_COMMON_PATH="/$DRIVE_PATH/comm/app/$vendor/$appId/app_common.sh"
	if [ ! -f "$APP_COMMON_PATH" ]; then
		error_log "$APP_COMMON_PATH not exist!"
		return 1
	fi

	APP_COMMON_PATH="$(tmrSelect "$APP_COMMON_PATH")"
	if [ $? -ne 0 ]; then
		error_log "tmrSelect failed!"
		return 1
	fi

	echo "$(bash "$APP_COMMON_PATH" "getver")"
}

canBusFileTransfer()
{
        if [ "$#" -ne 10 ]; then
                error_log "$@ command invalid!"
                return 1
        fi

        local vendor=$3
        local appId=$4
        local srcFilePath=$5
	local fType=$6
	local fSubType=$7
	local segFlag=$8
	local sliceNum=$9
	local length=$10

	if [ "$fType" == "FFH" ]; then
		if [ ! -d "/$DRIVE_PATH/comm/app/$vendor/$appId" ]; then
                        mkdir -p "/$DRIVE_PATH/comm/app/$vendor/$appId" > /dev/null
                fi

                # Three-Mode Storage
                tmrSaveAppCommonScript $vendor $appId $srcFilePath
        fi

}

ethernetFileTransfer()
{
	if [ "$#" -ne 7 ]; then
		error_log "$@ command invalid!"
		return 1
	fi

	local vendor=$3
	local appId=$4

	#if [ ! checkVendorAndAppIdLen $vendor $appId ]; then
	#	error_log "checkVendorAndAppIdLen failed!"
	#	return 1
	#fi

	local srcFilePath=$5
  local ftype=$6
  local fsubtype=$7
	mkdir -p "$DRIVE_PATH/tempspace"
	tar -xf "$srcFilePath" -C "$DRIVE_PATH/tempspace"
	extracted_file=$(tar -tf "$srcFilePath" | head -n 1 | cut -f1 -d'/')
	local extension="${extracted_file##*.}"

	if [ "$extension" == "sh" ]; then
    rm -rf "/$DRIVE_PATH/comm/app/$vendor/$appId"
		if [ ! -d "/$DRIVE_PATH/comm/app/$vendor/$appId" ]; then
			mkdir -p "/$DRIVE_PATH/comm/app/$vendor/$appId" > /dev/null
		fi

		# Three-Mode Storage
		tmrSaveAppCommonScript $vendor $appId "$DRIVE_PATH/tempspace/$extracted_file"

		# Set application workspace path
		APP_WORKSPACE_DIR="/$DRIVE_PATH/workspace/$vendor/$appId"
		if [ ! -d $APP_WORKSPACE_DIR ]; then
			mkdir -p "$APP_WORKSPACE_DIR" > /dev/null
		fi
		bash "$APP_COMMON_PATH" setpath "$APP_WORKSPACE_DIR"
	elif [ "$extension" == "tgz" ] || [ "$extension" == "0.tar.gz" ]; then
		APP_COMMON_PATH="/$DRIVE_PATH/comm/app/$vendor/$appId/app_common.sh"
		if [ ! -f "$APP_COMMON_PATH" ]; then
			error_log "$APP_COMMON_PATH not exist!"
			return 1
		fi

		APP_COMMON_PATH="$(tmrSelect "$APP_COMMON_PATH")"
		if [ $? -ne 0 ]; then
			error_log "tmrSelect failed!"
			return 1
		fi

		# Transfer app package file
		bash "$APP_COMMON_PATH" "readfile" "$DRIVE_PATH/tempspace/$extracted_file" "ftype" "fsubtype"> /dev/null 2>&1 
	else
		
		APP_COMMON_PATH="/$DRIVE_PATH/comm/app/$vendor/$appId/app_common.sh"
                if [ ! -f "$APP_COMMON_PATH" ]; then
                        error_log "$APP_COMMON_PATH not exist!"
                        return 1
                fi

                APP_COMMON_PATH="$(tmrSelect "$APP_COMMON_PATH")"
                if [ $? -ne 0 ]; then
                        error_log "tmrSelect failed!"
                        return 1
                fi

                # Transfer app package file
                bash "$APP_COMMON_PATH" "readfile" "$DRIVE_PATH/tempspace/$extracted_file" "ftype" "fsubtype"> /dev/null 2>&1 
	fi
	#sleep 5
	rm -rf "$DRIVE_PATH/tempspace"
}

selfReconstructPreparation()
{
	if [ $# -ne 4 ]; then
		error_log "$@ command invalid!"
		return 1
	fi
	
	local vendor=$3
	local appId=$4

	APP_COMMON_PATH="/$DRIVE_PATH/comm/app/$vendor/$appId/app_common.sh"

	if [ ! -f "$APP_COMMON_PATH" ]; then
		error_log "$APP_COMMON_PATH not exist!"
		return 0
	fi

	APP_COMMON_PATH="$(tmrSelect "$APP_COMMON_PATH")"
	if [ $? -ne 0 ]; then
		error_log "tmrSelect failed!"
		return 1
	fi

	local app_common_print=$(bash "$APP_COMMON_PATH" "prereconfig")
	if [ "$app_common_print" == "00H" ] || \
	   [ "$app_common_print" == "11H" ] || \
	   [ "$app_common_print" == "FFH" ]; then
		echo "$app_common_print"
	else
		error_log "$app_common_print"
		return 1
	fi
}

selfReconstructStart()
{
	if [ $# -ne 5 ]; then
		error_log "$@ command invalid!"
		return 1
	fi

	local vendor=$3
	local appId=$4
	local appVersion=$5
	
	APP_COMMON_PATH="/$DRIVE_PATH/comm/app/$vendor/$appId/app_common.sh"
	if [ ! -f "$APP_COMMON_PATH" ]; then
		error_log "$APP_COMMON_PATH not exist!"
		return 1
	fi

	APP_COMMON_PATH="$(tmrSelect "$APP_COMMON_PATH")"
	if [ $? -ne 0 ]; then
		error_log "tmrSelect failed!"
		return 1
	fi

	# app reconstruction
	bash "$APP_COMMON_PATH" "reconfig" "$appVersion" > /dev/null 2>&1 &
	#bash "$APP_COMMON_PATH" "reconfig" "$appVersion"
}

selfReconstructResultQuery()
{
	if [ $# -ne 4 ]; then
		error_log "$@ command invalid!"
		return 1
	fi

	local vendor=$3
	local appId=$4

	APP_COMMON_PATH="/$DRIVE_PATH/comm/app/$vendor/$appId/app_common.sh"
	if [ ! -f "$APP_COMMON_PATH" ]; then
		error_log "$APP_COMMON_PATH not exist!"
		return 1
	fi

	APP_COMMON_PATH="$(tmrSelect "$APP_COMMON_PATH")"
	if [ $? -ne 0 ]; then
		error_log "tmrSelect failed!"
		return 1
	fi

	local app_common_print="$(bash "$APP_COMMON_PATH" "chkreconfig")"
	if [ "$app_common_print" == "00H" ] || \
		[ "$app_common_print" == "11H" ] || \
		[ "$app_common_print" == "FFH" ]; then
		echo "$app_common_print"
	else
		error_log "$app_common_print"
		return 1
	fi
}

softwareFallback()
{
	if ! ([ $# -ge 4 ] || [ $# -le 5 ]); then
		error_log "$@ command invalid!"
		return 1
	fi

	local vendor=$3
	local appId=$4

	APP_COMMON_PATH="/$DRIVE_PATH/comm/app/$vendor/$appId/app_common.sh"
	if [ ! -f "$APP_COMMON_PATH" ]; then
		error_log "$APP_COMMON_PATH not exist!"
		return 1
	fi

	APP_COMMON_PATH="$(tmrSelect "$APP_COMMON_PATH")"
	if [ $? -ne 0 ]; then
		error_log "tmrSelect failed!"
		return 1
	fi

	local app_common_print=""
	if [ $# -eq 5 ]; then
		local version=$5
		app_common_print="$(bash "$APP_COMMON_PATH" "rollback" "$version")"
	else
		app_common_print="$(bash "$APP_COMMON_PATH" "rollback")"
	fi
	
	if [ "$app_common_print" != "00H" ] || \
		[ "$app_common_print" != "11H" ] || \
		[ "$app_common_print" != "FFH" ]; then
		error_log "$app_common_print"
		return 1
	fi

	echo "$app_common_print"
}

softwareFallbackResultQuery()
{
	if [ $# -ne 4 ]; then
		error_log "$@ command invalid!"
		return 1
	fi

	local vendor=$3
	local appId=$4

	APP_COMMON_PATH="/$DRIVE_PATH/comm/app/$vendor/$appId/app_common.sh"
	if [ ! -f "$APP_COMMON_PATH" ]; then
		error_log "$APP_COMMON_PATH not exist!"
		return 1
	fi

	APP_COMMON_PATH="$(tmrSelect "$APP_COMMON_PATH")"
	if [ $? -ne 0 ]; then
		error_log "tmrSelect failed!"
		return 1
	fi

	local app_common_print="$(bash "$APP_COMMON_PATH" chkrollback)"
	if [ $app_common_print == "00H" ] || [ $app_common_print == "11H" ]; then
		echo $app_common_print
	else
		error_log "$app_common_print"
		return 1
	fi
}

install()
{

        local vendor=$3
        local appId=$4
	    local pkgName=$7

        APP_COMMON_PATH="/$DRIVE_PATH/comm/app/$vendor/$appId/app_common.sh"
        if [ ! -f "$APP_COMMON_PATH" ]; then
                error_log "$APP_COMMON_PATH not exist!"
                return 1
        fi

	    APP_COMMON_PATH="$(tmrSelect "$APP_COMMON_PATH")"
        if [ $? -ne 0 ]; then
                error_log "tmrSelect failed!"
                return 1
        fi

        local app_common_print="$(bash "$APP_COMMON_PATH" install "$pkgName")"
        if [ $app_common_print == "00H" ] || [ $app_common_print == "11H" ]; then
                echo $app_common_print
        else
                error_log "$app_common_print"
                return 1
        fi
}

uninstall()
{
        local vendor=$3
        local appId=$4

        APP_COMMON_PATH="/$DRIVE_PATH/comm/app/$vendor/$appId/app_common.sh"
        if [ ! -f "$APP_COMMON_PATH" ]; then
                error_log "$APP_COMMON_PATH not exist!"
                return 1
        fi

        APP_COMMON_PATH="$(tmrSelect "$APP_COMMON_PATH")"
        if [ $? -ne 0 ]; then
                error_log "tmrSelect failed!"
                return 1
        fi

        local app_common_print="$(bash "$APP_COMMON_PATH" uninstall)"
	echo $app_common_print
}

startuppro()
{
        local vendor=$3
        local appId=$4

        APP_COMMON_PATH="/comm/app/$vendor/$appId/app_common.sh"
        if [ ! -f "$APP_COMMON_PATH" ]; then
                error_log "$APP_COMMON_PATH not exist!"
                return 1
        fi

        APP_COMMON_PATH="$(tmrSelect "$APP_COMMON_PATH")"
        if [ $? -ne 0 ]; then
                error_log "tmrSelect failed!"
                return 1
        fi

        local app_common_print="$(bash "$APP_COMMON_PATH" startuppro &)"
        echo $app_common_print
}

stoppro()
{
        local vendor=$3
        local appId=$4

        APP_COMMON_PATH="/comm/app/$vendor/$appId/app_common.sh"
        if [ ! -f "$APP_COMMON_PATH" ]; then
                error_log "$APP_COMMON_PATH not exist!"
                return 1
        fi

        APP_COMMON_PATH="$(tmrSelect "$APP_COMMON_PATH")"
        if [ $? -ne 0 ]; then
                error_log "tmrSelect failed!"
                return 1
        fi

        local app_common_print="$(bash "$APP_COMMON_PATH" stoppro)"
        echo $app_common_print
}

cleanwkspace()
{
        local vendor=$3
        local appId=$4
	local fileType=$7

        APP_COMMON_PATH="/$DRIVE_PATH/comm/app/$vendor/$appId/app_common.sh"
        if [ ! -f "$APP_COMMON_PATH" ]; then
                error_log "$APP_COMMON_PATH not exist!"
                return 1
        fi

        APP_COMMON_PATH="$(tmrSelect "$APP_COMMON_PATH")"
        if [ $? -ne 0 ]; then
                error_log "tmrSelect failed!"
                return 1
        fi

        local app_common_print="$(bash "$APP_COMMON_PATH" cleanwkspace "$fileType")"
        echo $app_common_print
}

monitor()
{
	fileName="autostart_not_allowed.txt"
	for script in /$DRIVE_PATH/comm/app/*/*/app_common.sh; do
		DIR=$(dirname "$script")
		if [ ! -f "$DIR/$fileName" ]; then
			bash "$script" monitor &
		fi
	done
}

getteledata()
{
        cmd=`tail -n 1 /nvme/nvme0n1p1/comm/common.log`
        echo "$cmd" > /tmp/cmd.txt
        read var1 var2 < /tmp/cmd.txt
        rm /tmp/cmd.txt
        for script in /comm/app/*/$var1/app_common.sh; do
                # 调用脚本中的monitor命令
                bash "$script" getteledata
        done
}

toggleAutoBootSwitch()
{
        local vendor=$3                                                                           
        local appId=$4
	IS_AUTOSTART_ALLOWED_PATH="/$DRIVE_PATH/comm/app/$vendor/$appId/autostart_not_allowed.txt"
	if [ ! -f "$IS_AUTOSTART_ALLOWED_PATH" ]; then
		touch $IS_AUTOSTART_ALLOWED_PATH
	else
		rm $IS_AUTOSTART_ALLOWED_PATH
	fi
}

autoBoot()
{
	local vendor=$3                                                                           
        local appId=$4
	APP_COMMON_PATH="/$DRIVE_PATH/comm/app/$vendor/$appId/app_common.sh"                      
        if [ ! -f "$APP_COMMON_PATH" ]; then                                          
                error_log "$APP_COMMON_PATH not exist!"                               
                return 1                                                              
        fi                                                                            
                                                                                    
        APP_COMMON_PATH="$(tmrSelect "$APP_COMMON_PATH")"                             
        if [ $? -ne 0 ]; then                                                         
                error_log "tmrSelect failed!"                                         
                return 1                                                              
        fi                                                                            
                                                                                      
        local app_common_print="$(bash "$APP_COMMON_PATH" initAndStart&)"  
        echo $app_common_print
}

main()
{
	if [ $# -le 1 ]; then
		echo "Command invalid!"
		usage
		exit 1
	fi

	CMD_TYPE=$1
	CMD_CODE=$2

	if [ ! -d "/comm" ]; then
    	ln -s /$DRIVE_PATH/comm /comm &
    fi 
    if [ ! -d "/workspace" ]; then
		ln -s /$DRIVE_PATH/workspace /workspace &
    fi
	#echo "CMD: $1, $2, $3, $4, $5, $6, $7" >> "/$DRIVE_PATH/comm/common.log"
	local rc=0
	case $CMD_CODE in
		# Software version query
		"3503H")
		softwareVersionQuery $@
		rc=$?
		;;
		# Ethernet file transfer
		"01DAH")
		ethernetFileTransfer $@
		rc=$?
		;;
		# CAN bus File transfer
		"01AAH")
		canBusFileTransfer $@
		rc=$?
		;;
		# Software reconstruction prepare
		"3403H")
		selfReconstructPreparation $@
		rc=$?
		;;
		# Software reconstruction start
		"340AH")
		selfReconstructStart $@
		rc=$?
		;;
		# Software reconstruction result query
		"340EH")
		selfReconstructResultQuery $@
		rc=$?
		;;
		# Software fallback
		"350AH")
		softwareFallback $@
		rc=$?
		;;
		# Software fallback result query
		"350CH")
		softwareFallbackResultQuery $@
		rc=$?
		;;
		# custom command
		"A205H")
		if [ $# -le 5 ]; then
                	echo "Command invalid!"
                	exit 1
                fi
		operation=$5
		case $operation in
			"00H")
				#install $@
        echo "$4 $5" >> "/$DRIVE_PATH/comm/common.log"
	install $@
			;;
      "03H")
				#uninstall $@
        echo "$4 $5" >> "/$DRIVE_PATH/comm/common.log"
	uninstall $@
			;;
			"01H")
				#startuppro $@
        echo "$4 $5" >> "/$DRIVE_PATH/comm/common.log"
	startuppro $@
			;;
			"02H")
				#stoppro $@
        echo "$4 $5" >> "/$DRIVE_PATH/comm/common.log"
	stoppro $@
			;;
			"05H")
				cleanwkspace $@
        echo "$4 $5" >> "/$DRIVE_PATH/comm/common.log"
			;;
      "06H")
        #toggleAutoBootSwitch $@
        echo "$4 $5" >> "/$DRIVE_PATH/comm/common.log"
	toggleAutoBootSwitch $@
      ;;
			"07H")
				#autoBoot $@
        echo "$4 $5" >> "/$DRIVE_PATH/comm/common.log"
			autoBoot $@
			;;
			*)
				echo "invalid operation"
				exit 1
			;;
		esac
		;;
		# monitor
		"1")
		monitor $@
		;;
		# getteledata
		"0055H")
    output=$(getteledata)
    cmd=`tail -n 1 /nvme/nvme0n1p1/comm/common.log`
    echo "$cmd" > /tmp/cmd.txt
    read var1 var2 < /tmp/cmd.txt
    rm /tmp/cmd.txt
    echo "${var1} ${output}"
		;;
		*)
		usage
		exit 1
		;;
	esac

	if [ $rc -ne 0 ]; then
		echo "command error!"
		exit 1
	fi
}

main $@
