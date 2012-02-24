echo Testing KSWriter

base=`dirname $0`
common="$base/../ECUnitTests/Scripts"
source "$common/test-common.sh"

# build & run the tests
xcodebuild -target "KSWriterTests" -configuration $testConfig -sdk "$testSDKMac" $testOptions | "$common/$testConvertOutput"
