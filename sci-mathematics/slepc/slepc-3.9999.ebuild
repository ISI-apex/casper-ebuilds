# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

EGIT_REPO_URI="https://gitlab.com/slepc/slepc.git"

PYTHON_COMPAT=( python3_{6,7,8} )

inherit eutils flag-o-matic python-single-r1 snapshot toolchain-funcs

if [[ ${PV} = *9999 ]]
then
	KEYWORDS=""
else
	KEYWORDS="~amd64 ~amd64-linux ~x86 ~ppc64 ~ppc64-linux"
fi

DESCRIPTION="Scalable Library for Eigenvalue Problem Computations"
HOMEPAGE="http://slepc.upv.es/"

LICENSE="LGPL-3"
SLOT="0"

IUSE="arpack complex-scalars index-64bit doc mpi python scalapack"

#TODO: QA about gmake job server: this is due to custom variable instead of $(MAKE)

BDEPEND="
	virtual/pkgconfig
	dev-util/cmake
	"
RDEPEND="
	=sci-mathematics/petsc-$(ver_cut 1-2)*:=[mpi=,complex-scalars=,index-64bit=,python=]
	arpack? ( sci-libs/arpack[mpi=] )
	scalapack? ( sci-libs/scalapack )
	mpi? ( virtual/mpi )
"

DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	"

PATCHES=(
	"${FILESDIR}"/${PN}-3.9999-conf-help-arg.patch
	"${FILESDIR}"/${PN}-3.9999-conf-cross-compile.patch
)

MAKEOPTS="${MAKEOPTS} V=1"

slepc_use_with() {
	local flag=$1
	local arg=${2:-${flag}}
	echo --with-${arg}=$(usex ${flag} 1 0)
}

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
		--have-petsc4py=1
		$(slepc_use_with arpack)
		$(slepc_use_with scalapack)
		$(slepc_use_with python slepc4py)
		# TODO: not packaged
		--with-elemental=0
		--with-feast=0
		--with-blopex=0
		--with-blzpack=0
		--with-elpa=0
		--with-evsl=0
		--with-primme=0
		--with-slicot=0
		--with-trlan=0
		# TODO: packaged, but don't have normal --with-X args
		# hpddm: off by default, but no --with-hpddm flag
		# sowing: off by default, but no --with-sowing flag
	)

	# configure is a custom python script and doesn't want to have default
	# configure arguments that we set with econf
	echo ./configure "${conf_args[@]}"
	./configure "${conf_args[@]}" || die
}

src_compile() {
	emake SLEPC_DIR="${S}"
}

src_install() {
	use python && python_setup
	local slepc_install_dir="${EPREFIX}"/usr/$(get_libdir)/slepc
	emake SLEPC_DIR="${S}" SLEPC_INSTALLDIR="${slepc_install_dir}" DESTDIR="${D}" install

	# slepc4py installs into SLEPC_DIR, so create shortcut from site dir
	if use python; then
		local dest_sitedir="${D}$(python_get_sitedir)"
		mkdir -p "${dest_sitedir}" || die
		# NOTE: contents of .pth needs to be one line
		echo \
			"import sys, os;" \
			"p = os.getenv('SLEPC_DIR');" \
		        "a = os.getenv('PETSC_ARCH') or '';" \
			"p = p and os.path.join(p, a, 'lib');" \
			"p and (p in sys.path or sys.path.append(p))" \
			> "${dest_sitedir}"/slepc4py.pth || die
	fi

	use python && python_optimize

	dosym "${EPREFIX}"/usr/$(get_libdir)/slepc/lib/pkgconfig/slepc.pc \
		/usr/$(get_libdir)/pkgconfig/slepc.pc

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
	snapshot_src_install
}
