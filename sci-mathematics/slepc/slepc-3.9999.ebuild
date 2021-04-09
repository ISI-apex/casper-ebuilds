# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

EGIT_REPO_URI="https://gitlab.com/slepc/slepc.git"

PYTHON_COMPAT=( python3_{6,7,8} )
SNAPSHOT_POS=4

inherit eutils flag-o-matic python-single-r1 snapshot toolchain-funcs

if [[ "${PV}" = *9999 ]]
then
	KEYWORDS=""
else
	KEYWORDS="~amd64 ~amd64-linux ~x86 ~ppc64 ~ppc64-linux"
fi

DESCRIPTION="Scalable Library for Eigenvalue Problem Computations"
HOMEPAGE="http://slepc.upv.es/"

LICENSE="LGPL-3"
SLOT="0"

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
		--with-slepc4py=$(usex python 1 0)
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
	use python && python_setup
	local slepc_install_dir="${EPREFIX}"/usr/$(get_libdir)/slepc
	emake SLEPC_DIR="${S}" SLEPC_INSTALLDIR="${slepc_install_dir}" DESTDIR="${D}" install
	use python && python_optimize

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
