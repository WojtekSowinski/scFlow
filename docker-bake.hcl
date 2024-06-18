group "default" {
    targets = ["minified", "with_dev_tools"]
}
target "minified" {
    tags = ["my_scflow/minified"]
    target = "squash"
}
target "with_dev_tools" {
    tags = ["my_scflow/with_dev_tools"]
    target = "with_dev_tools"
}
