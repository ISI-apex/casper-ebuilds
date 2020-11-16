# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3 cmake

DESCRIPTION="Library to read/write .npy and .npz files in C/C++"
HOMEPAGE="https://github.com/rogersce/cnpy"
EGIT_REPO_URI="https://github.com/rogersce/cnpy.git"

if [[ "$(ver_cut 2 ${PV})" = "pre" ]]
then
	MY_D="$(ver_cut 3 ${PV})"
	EGIT_COMMIT_DATE="${MY_D:0:4}-${MY_D:4:2}-${MY_D:6:2}"
	KEYWORDS="~amd64 ~amd64-linux"
else # live
	KEYWORDS=""
fi

LICENSE="MIT"
SLOT="0"
IUSE="static-libs"

DEPENDS="sys-libs/zlib"

PATCHES=("${FILESDIR}"/${PN}-9999-lib-suffix.patch)

src_configure() {
	local mycmakeargs=(
		-DENABLE_STATIC=$(usex static-libs)
	)
	cmake_src_configure
}

#src_compile() {
#	cmake_src_compile \
#		$(usex test build-tests "") \
#		$(usex examples build-examples "")
#}

#src_test() {
#	# TODO: Test_hmat_(vec|mat)_prod tests fail with:
#	#    Assertion `dirnorm >= 1.e-10' failed.
#	cmake_src_test -E 'Test_hmat_[^_]*_prod_[1-4]'
#}

#src_install() {
#	cmake_src_install
#
#	# TODO: Requires: hpddm ?
#	cat <<-EOF > ${PN}.pc
#	prefix=${EPREFIX}/usr
#	libdir=\${prefix}/$(get_libdir)
#	Name: ${PN}
#	Description: ${DESCRIPTION}
#	Version: ${PV}
#	URL: ${HOMEPAGE}
#	Libs: -L\${libdir} $($(tc-getPKG_CONFIG) --libs \
#		$(usex lapack lapack "") $(usex arpack arpack ""))
#	Cflags: -I\${prefix}/include/${PN}
#	EOF
#	insinto /usr/$(get_libdir)/pkgconfig
#	doins ${PN}.pc
#}
