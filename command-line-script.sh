#!/bin/bash

function die {
    # die $DIR Error message
    local DIR=$1
    shift
    local D=`date`
    echo "[ ERROR ] [ $D ] $*"
    exit 1
}

INITDIR=$PWD

if [ $# -lt 2 ]; then
  die ${INITDIR} "Needs 2 arguments and an optional flag. If you keep -r flag as an input, then the reprozip trace process is triggered . Usage: $0 [-r] <subject_folder> <name>"
fi

REPROZIP_FLAG=false
#If reprozip flag is set
if [ $# -eq 3 ]; then
  if [ $1 = "-r" ]; then 
    REPROZIP_FLAG=true
    SUBJECT_FOLDER=$2
    NAME=$3
  fi
else
  SUBJECT_FOLDER=$1
  NAME=$2
fi

EXECUTION_DIR=exec
BEFORE_FILE=${EXECUTION_DIR}/${SUBJECT_FOLDER}/checksums-before.txt
AFTER_FILE=${EXECUTION_DIR}/${SUBJECT_FOLDER}/checksums-after.txt

create-execution-dir.sh ${SUBJECT_FOLDER} ${EXECUTION_DIR}                               		  || die ${INITDIR} "Cannot create execution directory."
checksums.sh ${EXECUTION_DIR}/${SUBJECT_FOLDER}  > ${BEFORE_FILE}                        		  || die ${INITDIR} "Checksum script failed."
monitor.sh &> ${EXECUTION_DIR}/${SUBJECT_FOLDER}/monitor.txt                             		  || die ${INITDIR} "Monitoring script failed."
cd ${EXECUTION_DIR}                                                                      		  || die ${INITDIR} "Cannot cd to ${EXECUTION_DIR}."

#Adding the reprozip command to trace the processing of subjects
if [ ${REPROZIP_FLAG} = true ]; then
  reprozip trace PreFreeSurferPipelineBatch.sh --StudyFolder=$PWD --Subjlist=${SUBJECT_FOLDER} --runlocal || die ${INITDIR} "Pipeline failed."
else
  PreFreeSurferPipelineBatch.sh --StudyFolder=$PWD --Subjlist=${SUBJECT_FOLDER} --runlocal                || die ${INITDIR} "Pipeline failed."
fi

cd ${INITDIR}                                                                            		  || die ${INITDIR} "cd .. failed."
checksums.sh ${EXECUTION_DIR}/${SUBJECT_FOLDER} > ${AFTER_FILE}                          		  || die ${INITDIR} "Checksum script failed."

#Copying the .reprozip-trace folder in execution directory to the subject folder.
if [ ${REPROZIP_FLAG} = true ]; then
  cp -r ${EXECUTION_DIR}/.reprozip-trace ${EXECUTION_DIR}/${SUBJECT_FOLDER}
fi

ln -s ${EXECUTION_DIR}/${SUBJECT_FOLDER} ${SUBJECT_FOLDER}-${NAME}                       		  || die ${INITDIR} "Cannot link results."

