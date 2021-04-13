# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} )
DISTUTILS_SINGLE_IMPL=1

EGIT_REPO_URI="https://github.com/ISI-apex/casper-utils.git"
EGIT_SUBMODULES=()

if [[ ${PV} == *9999 ]]; then
	KEYWORDS=""
else
	KEYWORDS="~amd64 ~amd64-linux ~ppc64 ~ppc64-linux"
fi

inherit conf-overlay distutils-r1 git-r3 prefix-tools snapshot

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
		etc.in/prefix-tools/prefixrc > "${T}"/etc/prefix-tools/prefixrc

	insinto /
	doins -r "${T}"/etc
	doins -r etc

	insinto "${PREFIX_TOOLS_DIR}"
	if [[ -d "sh" ]]; then
		doins -r sh
	fi
	if [[ -d "make" ]]; then
		doins -r make
	fi

	for f in bin/*; do
		dobin $f
	done

	insinto "${PREFIX_TOOLS_HOST_DIR}"
	exeinto "${PREFIX_TOOLS_HOST_DIR}"
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
	snapshot_src_install
}
