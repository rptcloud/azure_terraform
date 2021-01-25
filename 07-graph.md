# Lab: Terraform Graph

Duration: 5 minutes

Terraform knows a lot about your configuration. We've already seen how to use
`terraform show` to output information about your resources. Terraform can also
present this data in DOT format, which is used by GraphVis and similar programs to generate graphs.

- Task 1: Generate a graph against your current Terraform configuration

## Task 1

### Step 7.1.1

Run `terraform graph` in your terraform directory and note the output.

```shell
terraform graph
```

```text
digraph {
	compound = "true"
	newrank = "true"
	subgraph "root" {
# ...
  }
}
```

### Step 7.1.2

Paste that output into [webgraphviz](http://www.webgraphviz.com) to get a visual representation of dependencies that Terraform creates for your configuration.
