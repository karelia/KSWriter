echo Testing Mac

base=`dirname $0`
config="-configuration Debug"
sdkMac="macosx"

# build & run the tests
xcodebuild -target "KSWriterTests" $config -sdk "$sdkMac" clean build | "${base}/ocunit2junit.rb"
