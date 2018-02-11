#!/bin/bash

#  Automatic build script for libssh2 
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 01.02.11.
#  Copyright 2010-2015 Felix Schulze. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
if [ "$1" == "openssl" ];
then
	echo "Building openssl:"
	./openssl/build-libssl.sh $2
	# Make dynamic framework, with embed-bitcode, iOS + Simulator:
	rm -rf build
	rm -rf openssl.framework
	xcodebuild -project libssh2-for-iOS.xcodeproj -target openssl -sdk iphoneos  -configuration Debug
	xcodebuild -project libssh2-for-iOS.xcodeproj -target openssl -sdk iphonesimulator  -configuration Debug
	cp -r build/Debug-iphoneos/openssl.framework .
	mkdir -p openssl.framework/Headers/
	cp include/openssl/* openssl.framework/Headers/
	lipo -create -output openssl.framework/openssl build/Debug-iphonesimulator/openssl.framework/openssl build/Debug-iphoneos/openssl.framework/openssl
	# if you don't need bitcode, use this line instead:
	# ./openssl/create-openssl-framework.sh dynamic
	echo "Build libssh2:"
	./build-libssh2.sh openssl
	# Make dynamic framework, with embed-bitcode, iOS + Simulator:
	rm -rf libssh2.framework
	xcodebuild -project libssh2-for-iOS.xcodeproj -target libssh2 -sdk iphoneos  -configuration Debug
	xcodebuild -project libssh2-for-iOS.xcodeproj -target libssh2 -sdk iphonesimulator  -configuration Debug
	cp -r build/Debug-iphoneos/libssh2.framework .
	mkdir -p libssh2.framework/Headers/
	cp include/libssh2/* libssh2.framework/Headers/
	lipo -create -output libssh2.framework/libssh2 build/Debug-iphonesimulator/libssh2.framework/libssh2 build/Debug-iphoneos/libssh2.framework/libssh2
	# if you don't need bitcode, use this line instead:
	# ./create-libssh2-framework.sh dynamic
elif [ "$1" == "libgcrypt" ];
then
	echo "Build libgpg-error:"
	./libgcrypt-for-ios/build-libgpg-error.sh
	echo "Build libgcrypt:"
	./libgcrypt-for-ios/build-libgcrypt.sh
	echo "Build libssh2:"
	./build-libssh2.sh libgcrypt
else
	echo "Usage: ./build-all.sh openssl | libgcrypt"
fi
