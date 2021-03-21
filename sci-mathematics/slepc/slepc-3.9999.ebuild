# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

EGIT_REPO_URI="https://gitlab.com/slepc/slepc.git"

PYTHON_COMPAT=( python3_{6,7,8} )

inherit eutils flag-o-matic git-r3 python-single-r1 toolchain-funcs

if [[ "$(ver_cut 4 ${PV})" = "p" ]]
then
	MY_D="$(ver_cut 5 ${PV})"
	EGIT_COMMIT_DATE="${MY_D:0:4}-${MY_D:4:2}-${MY_D:6:2}"
	KEYWORDS="~amd64 ~amd64-linux ~ppc64 ~ppc64-linux"
else # live
	KEYWORDS=""
fi

DESCRIPTION="Scalable Library for Eigenvalue Problem Computations"
HOMEPAGE="http://slepc.upv.es/"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~amd64-linux ~x86 ~ppc64 ~ppc64-linux"

IUSE="complex-scalars index-64bit doc mpi python"

# TODO: SOWING: BLOPEX: BLZPACK: HPDDM: PRIMME: SLICOT:
#TODO: QA about gmake job server: this is due to custom variable instead of $(MAKE)

BDEPEND="
	virtual/pkgconfig
	dev-util/cmake
	"
RDEPEND="
	=sci-mathematics/petsc-$(ver_cut 1-2)*:=[mpi=,complex-scalars=,index-64bit=]
	sci-libs/arpack[mpi=]
	mpi? ( virtual/mpi )
"

DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	"

PATCHES=(
	"${FILESDIR}"/${P}-slepc4py-root-destdir.patch
	"${FILESDIR}"/${P}-slepc4py-site-packages-install-dir.patch
)

MAKEOPTS="${MAKEOPTS} V=1"

src_configure() {
	# *sigh*
	addpredict "${PETSC_DIR}"/.nagged

	# Make sure that the environment is set up correctly:
	unset PETSC_DIR
	unset PETSC_ARCH
	unset SLEPC_DIR
	source "${EPREFIX}"/etc/env.d/99petsc
	export PETSC_DIR

	local conf_args=(
		--prefix="${EPREFIX}/usr/$(get_libdir)/slepc"
		--with-arpack=1
		$(use_with python slepc4py)
		#--with-arpack-dir="${EPREFIX}/usr/$(get_libdir)"
		#--with-arpack-flags="$(usex mpi "-lparpack,-larpack" "-larpack")"
	)

	# configure is a custom python script and doesn't want to have default
	# configure arguments that we set with econf
	echo ./configure "${conf_args[@]}"
	./configure "${conf_args[@]}"
}

src_compile() {
	emake SLEPC_DIR="${S}"
}

src_install() {
	python_setup
	#emake DESTDIR="${ED}" SLEPC_INSTALLDIR=/usr/$(get_libdir)/slepc install
	emake SLEPC_DIR="${S}" DESTDIR="${D}" install
	python_optimize

	# add PETSC_DIR to environmental variables
	cat >> 99slepc <<- EOF
		SLEPC_DIR=${EPREFIX}/usr/$(get_libdir)/slepc
		LDPATH=${EPREFIX}/usr/$(get_libdir)/slepc/lib
	EOF
	doenvd 99slepc

	if use doc ; then
		dodoc docs/slepc.pdf
		docinto html
		dodoc -r docs/*.html docs/manualpages
	fi
}
