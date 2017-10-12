#!/usr/bin/env bash

printError() {
    echo -e "\e[1m\e[97m$1: \e[31merror: \e[97m$2\e[0m"
}

# Function for detecting some kinds of trivial formatting fail.
findFail() {
    FAIL=`grep -n $1 $2 | head -n 1 | cut -d ':' -f 1`
    if [ ! $FAIL = "" ]; then
        printError $2:$FAIL $3
        exit 1
    fi
}

# Weed out trivial formatting fails right away...
findFail $'^ *\t' $1 "line indented with tab characters"
findFail $'\\s$' $1 "Trailing whitespace"
findFail $'\r'\$ $1 "CRLF detected - use LF instead"

# Most, but not quite all, of the available checks:
# https://clang.llvm.org/extra/clang-tidy/checks/list.html
CHECKS=clang-analyzer-*,\
       boost-use-to-string,\
       bugprone-integer-division,\
       bugprone-suspicious-memset-usage,\
       bugprone-undefined-memory-manipulation,\
       cert-err52-cpp,\
       cert-err60-cpp,\
       cert-flp30-c,\
       cppcoreguidelines-interfaces-global-init,\
       cppcoreguidelines-no-malloc,\
       cppcoreguidelines-slicing,\
       google-explicit-constructor,\
       google-runtime-member-string-references,\
       llvm-namespace-comment,\
       misc-assert-side-effect,\
       misc-bool-pointer-implicit-conversion,\
       misc-dangling-handle,\
       misc-definitions-in-headers,\
       misc-forward-declaration-namespace,\
       misc-inaccurate-erase,\
       misc-incorrect-roundings,\
       misc-inefficient-algorithm,\
       misc-lambda-function-name,\
       misc-move-constructor-init,\
       misc-move-forwarding-reference,\
       misc-multiple-statement-macro,\
       misc-non-copyable-objects,\
       misc-redundant-expression,\
       misc-string-constructor,\
       misc-string-integer-assignment,\
       misc-string-literal-with-embedded-nul,\
       misc-suspicious-enum-usage,\
       misc-suspicious-missing-comma,\
       misc-suspicious-semicolon,\
       misc-swapped-arguments,\
       misc-unconventional-assign-operator,\
       misc-undelegated-constructor,\
       misc-uniqueptr-reset-release,\
       misc-unused-alias-decls,\
       misc-unused-raii,\
       misc-unused-using-decls,\
       misc-use-after-move,\
       modernize-deprecated-headers,\
       modernize-loop-convert,\
       modernize-make-unique,modernize-make-shared,\
       modernize-redundant-void-arg,\
       modernize-replace-auto-ptr,\
       modernize-replace-random-shuffle,\
       modernize-shrink-to-fit,\
       modernize-use-bool-literals,\
       modernize-use-emplace,\
       modernize-use-equals-default,modernize-use-equals-delete,\
       modernize-use-noexcept,\
       modernize-use-nullptr,\
       modernize-use-override,\
       performance-faster-string-find,\
       performance-for-range-copy,\
       performance-implicit-conversion-in-loop,\
       performance-inefficient-string-concatenation,\
       performance-inefficient-vector-operation,\
       performance-type-promotion-in-math-fn,\
       performance-unnecessary-copy-initialization,\
       performance-unnecessary-value-param,\
       readability-avoid-const-params-in-decls,\
       readability-braces-around-statements,\
       readability-container-size-empty,\
       readability-deleted-default,\
       readability-delete-null-pointer,\
       readability-misleading-indentation,\
       readability-misplaced-array-index,\
       readability-redundant-control-flow,\
       readability-redundant-declaration,\
       readability-redundant-function-ptr-dereference,\
       readability-redundant-member-init,\
       readability-redundant-smartptr-get,\
       readability-redundant-string-cstr,\
       readability-redundant-string-init,\
       readability-simplify-boolean-expr,\
       readability-static-accessed-through-instance,\
       readability-static-definition-in-anonymous-namespace,\
       readability-uniqueptr-delete-release


TIDY_ARGS="-warnings-as-errors=* -checks=$CHECKS $@"

TMP_SCRIPT=$(mktemp)

# A self-deleting shell-script that runs the compilation job.
cat << EOF > $TMP_SCRIPT
set -o errexit
clang-tidy ${TIDY_ARGS}
rm $TMP_SCRIPT
EOF
chmod a+x $TMP_SCRIPT

# Run the script, using socat to trick it into yielding colour output.
# socat propagates the return code of the script, and hence any failure from
# clang-tidy.
socat -du EXEC:$TMP_SCRIPT,pty,stderr STDOUT
