# LSF Resource Connector and EC2 Spot

## Spot Fleet Allocation Strategies

LSF Resource Connector uses AWS EC2 Spot Fleet for requesting Spot instances.  However, it does not support all of the features of Spot Fleet, which could pose some challenges as you start to scale out on Spot. Specifically, Spot Fleet allocation strategies determine how it fulfills your Spot Fleet request.  RC currently supports on the first two allocation strategies below:
 
* `lowestPrice` (SUPPORTED IN RC)
  
  The Spot Instances come from the pool with the lowest price. This is the default strategy.
 
* `diversified` (SUPPORTED IN RC)

  The Spot Instances are distributed across all pools.
 
* `capacityOptimized` (NOT SUPPORTED IN RC)

  The Spot Instances come from the pool with optimal capacity for the number of instances that are launching.  Also, by offering the possibility of fewer interruptions, the capacityOptimized strategy can lower the overall cost of your workload.
 
As you start to do large-scale runs on Spot, in most cases `capacityOptimized` will be what you want in order to acquire the most capacity with the fewest Spot interruptions.

## Handling of Spot Terminations

* Jobs are requeued to the top of the queue by default. 

## Spot Fleet Requests

* RC's default maximum spot fleet request is 300 instances at a time.  It will add smaller requests to reach the target capacity.  Override this default with `RC_MAX_REQUESTS` in `lsb.params`.  Also, be aware of any instance limits in `policy_config.json`, `awsprov_templates.json`, or `LSB_RC_MAX_INSTANCES_PER_TEMPLATE` in `lsf.conf`.

