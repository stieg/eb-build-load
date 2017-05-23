# See what is happening if DEBUG is set.
[ -n "$DEBUG" ] && set -x
set -e

function test_app()
{
    which $1 &>/dev/null && return;
    error "Application \"$1\" is required for this app to run"
    exit 1
}

function test_set() {
    [ -n "$(eval echo \$$1)" ] && return;

    error "FAILURE: Required key \"$2\" has no value."
    exit 1
}

# Begin app
test_app "aws"
test_app "git"
test_app "zip"

test_set 'WERCKER_EB_BUILD_LOAD_AWS_ACCESS_KEY' 'aws_access_key'
test_set 'WERCKER_EB_BUILD_LOAD_AWS_REGION' 'aws_region'
test_set 'WERCKER_EB_BUILD_LOAD_AWS_SECRET_KEY' 'aws_secret_key'
test_set 'WERCKER_EB_BUILD_LOAD_EB_APP_NAME' 'eb_app_name'
test_set 'WERCKER_EB_BUILD_LOAD_S3_BUCKET' 's3_bucket'

# Setup the amazon config and populate the default profile
AWS_CONFIG="$HOME/.aws/config"
mkdir -p $(dirname $AWS_CONFIG)
touch $AWS_CONFIG
chmod 600 $AWS_CONFIG
cat > $AWS_CONFIG <<EOF
[default]
aws_access_key_id = $WERCKER_EB_BUILD_LOAD_AWS_ACCESS_KEY
aws_secret_access_key = $WERCKER_EB_BUILD_LOAD_AWS_SECRET_KEY
output = json
region = $WERCKER_EB_BUILD_LOAD_AWS_REGION
EOF


# Either use the provided version or use the git version.
GIT_VERSION="$(git describe --always --dirty)"
VERSION="${WERCKER_EB_BUILD_LOAD_EB_VERSION+$GIT_VERSION}"
ARCHIVE_NAME="${APPLICATION_NAME}-${VERSION}.zip"
BUILD_DIR="$(mktemp --dir)"
ARCHIVE_PATH="${BUILD_DIR}/${ARCHIVE_NAME}"
S3_URL="s3://${WERCKER_EB_BUILD_LOAD_S3_BUCKET}/${ARCHIVE_NAME}"

# Use a zipexclude file if one is provided.
ZIP_OPTS="--symlinks -9qr"
[ -r "$WERCKER_ROOT/.zipexclude" ] && ZIP_OPTS="$ZIP_OPTS -x@.zipexclude"

# Do this in a subshell so as not to alter our CWD
(
    cd $WERCKER_ROOT &&
     zip $ZIP_OPTS "${ARCHIVE_PATH}" .
)

aws s3 cp --acl private "$ARCHIVE_PATH" "$S3_URL"
rm -rf "$BUILD_DIR"

aws elasticbeanstalk create-application-version \
    --application-name "$WERCKER_EB_BUILD_LOAD_EB_APP_NAME" \
    --source-bundle "S3Bucket=${S3_BUCKET},S3Key=${ARCHIVE_NAME}" \
    --version-label "$VERSION" \
