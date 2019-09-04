# Experimental testbed for fine-grained memory allocation and precise time measurements in cloud functions

With this research codebase, we check how:
- cloud functions can be metered with millisecond precision, to avoid 100ms idleness penalties
- memory can be assigned dynamically to the container isolation to account for alteration while avoiding unused memory penalties

Both Docker and alternative containerisation technologies will be explored for this purpose.

## Docker measurements

Measurements of time and memory costs for docker containers.

Running an example (it takes a while and requires a lot of diskspace):
docker run --name benchmark unimarijo/linux-benchmarks & ./stats.sh benchmark

Running another, simpler example:
(docker run --name hello hello-world & ./stats.sh hello); docker rm hello
