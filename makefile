ARCHS			?=ios64-cross-arm64 ios-sim-cross-x86_64
SDKVERSION		?=13.4
OPENSSLVERSION  ?=1.1.0l
LIBSSH2VERSION  ?=1.9.0
OPENSSLVERSION_ :=$(shell echo ${OPENSSLVERSION} | sed 's/\./_/g')

demo:
	echo ${OPENSSLVERSION_}

.PHONY: build
build:
	./build-all.sh openssl
	xcrun -sdk iphoneos lipo -info libssh2.framework/libssh2
	xcrun -sdk iphoneos lipo -info openssl.framework/openssl

clean:
	rm -rf bin lib src *.gz include/

openssl-${OPENSSLVERSION}.tar.gz:
	curl -Lo openssl_${OPENSSLVERSION}.tar.gz https://github.com/openssl/openssl/archive/OpenSSL_${OPENSSLVERSION_}.tar.gz
	touch $@

openssl: src/openssl-${OPENSSLVERSION}/config

src/openssl-${OPENSSLVERSION}/config: openssl-${OPENSSLVERSION}.tar.gz
	tar -zxvf openssl-${OPENSSLVERSION}.tar.gz --directory src
	touch $@

# bin/iPhoneSimulator13.4-x86_64.sdk/lib/libssl.a
# bin/iPhoneOS13.4-cross.sdk/lib/libssl.a
# bin/iPhoneOS13.4-arm64.sdk/lib/libssl.a

libssh:
# libssh2 assumes it is running in the libssh2 directory
	cd src/libssh2-${LIBSSH2VERSION} \
	./build-libssh2.sh openssl
	rm -rf libssh2.framework
	xcodebuild -UseModernBuildSystem=NO -project libssh2-for-iOS.xcodeproj -target libssh2 -sdk iphoneos  -configuration Debug
	mkdir -p build/Debug-iphoneos/libssh2.framework/Headers/
	cp include/libssh2/* build/Debug-iphoneos/libssh2.framework/Headers/
	xcodebuild -UseModernBuildSystem=NO -project libssh2-for-iOS.xcodeproj -target libssh2 -sdk iphonesimulator -destination 'platform=iOS Simulator,OS=13.4' -arch x86_64 -arch i386  -configuration Debug
	mkdir -p build/Debug-iphonesimulator/libssh2.framework/Headers/
	cp include/libssh2/* build/Debug-iphonesimulator/libssh2.framework/Headers/
	cp -r build/Debug-iphoneos/libssh2.framework .
	lipo -create -output libssh2.framework/libssh2 build/Debug-iphonesimulator/libssh2.framework/libssh2 build/Debug-iphoneos/libssh2.framework/libssh2

libssl: build/13.4/ios64-cross-arm64/1.1.0l/lib/libssl.a
	rm -rf build
	rm -rf openssl.framework
	xcodebuild -project libssh2-for-iOS.xcodeproj -UseModernBuildSystem=NO -target openssl -sdk iphoneos  -configuration Debug
	mkdir -p build/Debug-iphoneos/openssl.framework/Headers/
	cp include/openssl/* build/Debug-iphoneos/openssl.framework/Headers/
	xcodebuild -project libssh2-for-iOS.xcodeproj -UseModernBuildSystem=NO -target openssl -sdk iphonesimulator -destination 'platform=iOS Simulator,OS=13.4' -arch x86_64 -arch arm64  -configuration Debug
	mkdir -p build/Debug-iphonesimulator/openssl.framework/Headers/
	cp include/openssl/* build/Debug-iphonesimulator/openssl.framework/Headers/
	cp -r build/Debug-iphoneos/openssl.framework .
	lipo -create -output openssl.framework/openssl build/Debug-iphonesimulator/openssl.framework/openssl build/Debug-iphoneos/openssl.framework/openssl

TARGETS := $(foreach arch,$(ARCHS),build/${SDKVERSION}/$(arch)/${OPENSSLVERSION}/lib/libssl.a)

# Build opeenssl for a specific architecture
$(TARGETS): ARCH=$(shell echo $@ | awk -F'/' '{print $$3}')
$(TARGETS): PREFIX=${PWD}/$(shell dirname $(shell dirname $@))
$(TARGETS): openssl
	@echo "Building $PREFIX"
	@echo "SDKVersion: ${SDKVERSION}"
	@echo "Arch:       ${ARCH}"
	@echo "OpenSSL:    ${OPENSSLVERSION}"
	./build-libssl.sh --targets=${ARCH} \
		--version=${OPENSSLVERSION} \
		--ios-sdk=${SDKVERSION} \
		--prefix=${PREFIX}
