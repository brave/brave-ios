This directory contains CQ client library to be distributed to other repos. If
you need to modify some files in this directory, please make sure that you are
changing the canonical version of the source code and not one of the copies,
which should only be updated as a whole using Glyco (when available, see
[chromium issue 489420](http://crbug.com/489420)).

The canonical version is located at `https://chrome-internal.googlesource.com/
infra/infra_internal/+/master/commit_queue/cq_client`.

You'll need to use protoc version 2.6.1 and
recent golang/protobuf package. Sadly, the latter has neither tags nor versions.

You can get protobuf by downloading archive from
https://github.com/google/protobuf/tree/v2.6.1 and manually building it. As for
golang compiler, if you have go configured, just

    go get -u github.com/golang/protobuf/{proto,protoc-gen-go}

TODO(tandrii,sergiyb): decide how to pin the go protobuf generator.

To generate `cq_pb2.py` and `cq.pb.go`:

    cd commit_queue/cq_client
    protoc cq.proto --python_out $(pwd) --go_out $(pwd)

Additionally, please make sure to use proto3-compatible syntax, e.g. no default
values, no required fields. Ideally, we should use proto3 generator already,
however alpha version thereof is still unstable.

