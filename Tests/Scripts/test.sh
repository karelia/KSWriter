echo Testing Mac

base=`dirname $0`
config="-configuration Debug"
sdkMac="macosx"
options="clean build TEST_AFTER_BUILD=YES"

CONVERT_OUTPUT="${base}/ocunit2junit.rb"

# build & run the tests
xcodebuild -target "KSWriterTests" $config -sdk "$sdkMac" ${options} | "${CONVERT_OUTPUT}"
