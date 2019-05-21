# Usage Guide

## Dependencies

### R

#### Anaconda

r-essentials

https://anaconda.org/r/r-essentials 

`conda create -p ~/r_env --copy -y -q -c r r-essentials python=2.7`

#### CDSW Engine

In case there is a mismatch, you will see the log below in STDOUT of the worker process. 

`ERROR sparklyr: RScript (3132) terminated unexpectedly: package 'reticulate’ was installed by an R version with different internals; it needs to be reinstalled for use with this R version`

## Environment

### Resource

Worker: t2.2xlarge - vCPU 8, RAM 32G

### Configuration

#### Memory Allocation
#### Container Memory

yarn.nodemanager.resource.memory-mb (NODEMANAGER worker Group)

12GB
 
#### Container Memory Maximum 

yarn.scheduler.maximum-allocation-mb (REROURCEMANAGER master Group)

64GB


#### Memory Check

NodeManager Advanced Configuration Snippet (Safety Valve) for yarn-site.xml
```
<property><name>yarn.nodemanager.pmem-check-enabled</name><value>false</value></property>
```
## Reference
* https://issues.apache.org/jira/browse/YARN-4714?page=com.atlassian.jira.plugin.system.issuetabpanels%3Aall-tabpanel

* https://hadoop.apache.org/docs/r2.7.7/hadoop-yarn/hadoop-yarn-common/yarn-default.xml

I disabled pmem-check reffering to the link below (although vmem is mentioned in the log).

* https://community.cloudera.com/t5/Batch-Processing-and-Workflow/How-to-set-yarn-nodemanager-pmem-check-enabled/td-p/30134

The following links were found when considering this issue.

* https://stackoverflow.com/questions/40781354/container-killed-by-yarn-for-exceeding-memory-limits-10-4-gb-of-10-4-gb-physic

* https://mapr.com/blog/best-practices-yarn-resource-management/

