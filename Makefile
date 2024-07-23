image:
	docker buildx build --platform linux/amd64,linux/arm64 -t simonwarpstream/warpstream-byoc-demo:latest --push .
