#!/bin/bash
echo "vvvvvvvvvvvvvvvvvvv  pbuilder_env.sh vvvvvvvvvvvvvvvvvvvvvv"
date
export WORKSPACE=$1
echo $WORKSPACE

echo "Set up environment variables"
. $WORKSPACE/env_vars.sh
echo "Job-Type: $JOBTYPE"

export PATH=$PATH:/usr/local/bin
. /opt/ros/$ROSDISTRO/setup.sh
export ROS_PACKAGE_PATH=/tmp/test_repositories/src_repository:$ROS_PACKAGE_PATH
export PYTHONPATH=$WORKSPACE/jenkins_setup/src:$PYTHONPATH



echo "Set up ssh"
export HOME="/root"
cp -a $WORKSPACE/.ssh /root &&
ls -la /root/ &&
chown -R root.root /root/.ssh
if [ $? != 0 ]; then
    echo "Could not successfully set up ssh"
    exit 1
fi

export DIR=$WORKSPACE/jenkins_setup/scripts/graphicTest/chroot
case $JOBTYPE in
    regular_graphics_test|prio_graphics_test)
        echo "Set up graphic"

        $DIR/checkDisplayNull.bash &&
        $DIR/setupSources.bash &&
        $DIR/../tvnc/installTurboVNC.bash &&
        $DIR/../vgl/installVirtualGL.bash &&
        $DIR/installSimulationPrerequisites.bash &&
        $DIR/distUpgrade.bash &&
        $DIR/installNvidia.bash &&
        $DIR/setupOGRE.bash
        if [ $? != 0 ]; then
            echo "Could not successfully prepare chroot"
            exit 1
        fi

        $DIR/remoteX.py start
        export DISPLAY=`cat /tmp/vncDisplay`
        echo "Using Display: $DISPLAY"
        ;;
esac

echo "======================================================"
echo " Listing environment variables for debugging purposes "
echo "======================================================"
env

echo
echo
echo "============================================================"
echo "==== Begin" $SCRIPT "script.    Ignore the output above ===="
echo "============================================================"

date
if [ $JOBTYPE == "graphic_test" ] || [ $JOBTYPE == "prio_graphics_test" ]; then
    graphic_test="true"
else
    graphic_test="false"
fi
if [ "$BUILD_REPO_ONLY" == true ]; then
    build_repo_only="true";
else
    build_repo_only="false";
fi

$WORKSPACE/jenkins_setup/scripts/${JOBTYPE}.py $PIPELINE_REPOS_OWNER $JENKINS_MASTER $JENKINS_USER $ROSDISTRO $REPOSITORY $graphic_test $build_repo_only
result=$?

if [ ! -z "$DISPLAY" ] && [ "$DISPLAY" != ":0" ]; then
    $DIR/remoteX.py stop
fi



date
echo "============================================================"
echo "==== End" $SCRIPT "script.    Ignore the output below ======"
echo "============================================================"
exit $result
