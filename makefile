.PHONY: build
build:
	./build-all.sh openssl
	xcrun -sdk iphoneos lipo -info libssh2.framework/libssh2
	xcrun -sdk iphoneos lipo -info openssl.framework/openssl

clean:
	rm -rf bin lib src *.gz include/
