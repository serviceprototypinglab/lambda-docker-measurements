# Experimental testbed for fine-grained memory allocation and precise time measurements in cloud functions

With this research codebase, we check how:
- cloud functions can be metered with millisecond precision, to avoid 100ms idleness penalties
- memory can be assigned dynamically to the container isolation to account for alteration while avoiding unused memory penalties

Both Docker and alternative containerisation technologies will be explored for this purpose.

## Docker measurements

Measurements of time and memory costs for docker containers.

Running an example (it takes a while and requires a lot of diskspace):
./measure-image.sh unimarijo/linux-benchmarks

Running another, simpler example:
./measure-image.sh yyekhlef/sleep

Running another, short-lived example [currently breaks measurements!]:
./measure-image.sh hello-world
