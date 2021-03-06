# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} )
DISTUTILS_SINGLE_IMPL=1

EGIT_REPO_URI="https://github.com/ISI-apex/casper-utils.git"
EGIT_SUBMODULES=()

if [[ "$(ver_cut 2 ${PV})" = "pre" ]]
then
	MY_D="$(ver_cut 3 ${PV})"
	EGIT_COMMIT_DATE="${MY_D:0:4}-${MY_D:4:2}-${MY_D:6:2}"
	KEYWORDS="~amd64 ~amd64-linux ~ppc64 ~ppc64-linux"
else # live
	KEYWORDS=""
fi

inherit conf-overlay distutils-r1 git-r3

DESCRIPTION="Tools for running commands within Gentoo Prefix"
HOMEPAGE="https://github.com/ISI-apex/casper-utils"
SLOT="0"
LICENSE="GPL-3"
IUSE=""

S="${WORKDIR}/${P}/prefix-tools"

CONF_OVERLAY_FILES=(
	"etc/openmpi-mca-params.conf"
	"etc/prte-mca-params.conf"
)

src_compile() {
	for d in python/*; do
		pushd "${d}"
		BUILD_DIR="${WORKDIR}/${d}"
		python_setup
		distutils-r1_python_compile
		popd
	done
}

src_install() {
	mkdir -p "${T}"/etc/prefix-tools
	sed -e "s:@__EPREFIX__@:${EPREFIX}:g" \
		-e "s:@__ETC_PTOOLS__@:etc/${PN}:g" \
		etc.in/prefix-tools/prefixrc > "${T}"/etc/prefix-tools/prefixrc

	insinto /
	doins -r "${T}"/etc
	doins -r etc

	for f in bin/*; do
		dobin $f
	done

	local ptools_dir=/ptools
	insinto ${ptools_dir}
	exeinto ${ptools_dir}
	doins host/pscommon.sh
	for f in host/*; do
		doexe $f
	done

	for d in python/*; do
		pushd "${d}"
		BUILD_DIR="${WORKDIR}/${d}"
		python_setup
		distutils-r1_python_install
		popd
	done
}
