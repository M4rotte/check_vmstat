#!/usr/bin/env sh

# set -x

# Default values

## General behaviour
RETURN_CODE=3                # UNKNOWN : Status if anything goes wrong past this line.
ERROR_PREFIX=''              # No prefix for error message by default
OK_PREFIX=''                 # No prefix for OK message by default
WARNING=10
CRITICAL=20
VALUE='wa'
DELAY=5
UNIT=''

# What pager is available?
if env less 2>/dev/null
then pager='less'
else pager='more'
fi

# Help message
help_message() {
$pager <<EOF

$(basename "$0")

Check some values from the vmstat output.

Only one value is checked at once, so is present in the performance data.

The checked value is common between GNU/Linux and AIX hosts. As an example, "in" matches the "bi" column on GNU/Linux hosts and the "fi" column on AIX hosts.

Usage: $(basename "$0") -w <warning threshold> -c <critical threshold> [-v <value>] [-d <delay>]

 -w/--warning      <threshold>  Warning threshold.
 
 -c/--critical     <threshold>  Critical threshold.
 
 -v/--value        <value>      Value monitored. Default is "wa" (IOWait)
                                Supported values are: wa,in,out
                                
                                 - wa  : CPU IO Wait % (wa)
                                 - in  : blk/s in on Linux (bi), file page-ins/s on AIX (fi)
                                 - out : blk/s out on Linux (bo), file page-outs/s on AIX (fo)
                                
 -d/--delay        <delay>      Total delay in second. Probes are done every second.
                                So a delay of N means that the returned value is an average on N probes.
                                Default is 5.

EOF
}

# Arguments management #

## KISS way to handle long options
for arg in "${@}"; do
  shift
  case "${arg}" in
     ("--warning")   set -- "${@}" "-w" ;;
     ("--critical")  set -- "${@}" "-c" ;;
     ("--value")     set -- "${@}" "-v" ;;
     ("--delay")     set -- "${@}" "-d" ;;
     (*)             set -- "${@}" "${arg}"
  esac
done;

## Parse command line options
while getopts "w:c:v:d:" opt; do
    case "${opt}" in
        (w)
            WARNING=${OPTARG}
            ;;
        (c)
            CRITICAL=${OPTARG}
            ;;
        (v)
            VALUE="${OPTARG}"
            ;;            
        (d)
            DELAY="${OPTARG}"
            ;;            
        (\?)
            printf "%s\n" "Unsupported option…";
            help_message;
            RETURN_CODE=3
            exit "${RETURN_CODE}";
            ;;
    esac
done;

## Main
case "$(uname)" in
    ('Linux')
    case "$VALUE" in
        ('wa')
        CAPTION="IO Wait"
        VMSTAT_CMD='vmstat -n 1 '$(( $DELAY + 1 ))"| tail -"$DELAY" |awk '{sum+=\$16} END {print sum}'"
        UNIT='%'
        ;;
        ('in')
        CAPTION="IO block ins"
        VMSTAT_CMD='vmstat -n 1 '$(( $DELAY + 1 ))"| tail -"$DELAY" |awk '{sum+=\$9} END {print sum}'"
        UNIT='blkps'
        ;;
        ('out')
        CAPTION="IO block outs"
        VMSTAT_CMD='vmstat -n 1 '$(( $DELAY + 1 ))"| tail -"$DELAY" |awk '{sum+=\$10} END {print sum}'"
        UNIT='blkps'
        ;;
        (*)
        echo "Unsupported value for option -v." && exit 3
        ;;
    esac
    ;;
    ('AIX')
    case "$VALUE" in
        ('wa')
        CAPTION="IO Wait"
        VMSTAT_CMD='vmstat 1 '$DELAY"| tail -"$DELAY" |awk '{sum+=\$17} END {print sum}'"
        UNIT='%'
        ;;
        ('in')
        CAPTION="IO File page ins"
        VMSTAT_CMD='vmstat -I 1 '$DELAY"| tail -"$DELAY" |awk '{sum+=\$6} END {print sum}'"
        UNIT='pps'
        ;;
        ('out')
        CAPTION="IO File page outs"
        VMSTAT_CMD='vmstat -I 1 '$DELAY"| tail -"$DELAY" |awk '{sum+=\$7} END {print sum}'"
        UNIT='pps'
        ;;
        (*)
        echo "Unsupported value for option -v." && exit 3
        ;;
    esac    
    ;;
esac


RETURN_VALUE=$(eval "$VMSTAT_CMD")

[ -z $RETURN_VALUE ] && RETURN_VALUE=0

[ $RETURN_VALUE -lt $(( $WARNING * $DELAY ))  ]  && { RETURN_CODE=0; }
[ $RETURN_VALUE -ge $(( $WARNING * $DELAY ))  ]  && { RETURN_CODE=1; }
[ $RETURN_VALUE -ge $(( $CRITICAL * $DELAY )) ]  && { RETURN_CODE=2; }

REAL_VALUE=$(echo "scale=2;$RETURN_VALUE/$DELAY" |bc -l |awk '{printf "%.2f", $0}')

PERF_CAPTION=$(printf "%s" "$CAPTION" |sed -e 's/ /_/g')


PERFDATA="${PERF_CAPTION}=${REAL_VALUE}${UNIT};$WARNING;$CRITICAL"

case $RETURN_CODE in
    (0)
        RETURN_MESSAGE="${CAPTION}: ${REAL_VALUE} $UNIT ($DELAY)"
        ;;
    (1)
        RETURN_MESSAGE="${CAPTION}: ${REAL_VALUE} $UNIT ($DELAY)"
        ;;
    (2)
        RETURN_MESSAGE="${CAPTION}: ${REAL_VALUE} $UNIT ($DELAY)"
        ;;
esac


printf "%s\n" "${RETURN_MESSAGE}|$PERFDATA"
exit ${RETURN_CODE}
