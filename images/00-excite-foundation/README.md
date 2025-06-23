# exc/foundation

The exc/foundation image provides a secure, minimal Debian-based environment for reproducible builds and containerized workloads. It establishes baseline conventions, user permissions, and runtime behavior for downstream ExCITE project images.



## Development

Use --no-cache to ensure images are built without issue.
```{bash}
docker buildx build --no-cache -t exc/foundation:0.1 .
```

If you are testing the stack locally and not using any registry images, you need to build images with --load

```{bash}
docker buildx build --load --no-cache -t exc/foundation:0.1 .
```

Use the following command to access the shell:
```{bash}
docker run -it --rm exc/foundation:0.1
```