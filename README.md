# check_vmstat.sh

Check some values from the vmstat output.

Only one value is checked at once, so is present in the performance data.

The checked value is common between GNU/Linux and AIX hosts. As an example, "in" matches the "bi" column on GNU/Linux hosts and the "fi" column on AIX hosts.

Usage: check_vmstat.sh -w <warning threshold> -c <critical threshold> [-v <value>] [-d <delay>]

 -w/--warning      <threshold>  Warning threshold.
 
 -c/--critical     <threshold>  Critical threshold.
 
 -v/--value        <value>      Value monitored. Default is "wa" (IOWait)
                                Supported values are: wa,in,out
                                
* wa  : CPU IO Wait % (wa)
* in  : blk/s in on Linux (bi), file page-ins/s on AIX (fi)
* out : blk/s out on Linux (bo), file page-outs/s on AIX (fo)
                                
 -d/--delay        <delay>      Total delay in second. Probes are done every second.
                                So a delay of N means that the returned value is an average on N probes.
                                Default is 5.

