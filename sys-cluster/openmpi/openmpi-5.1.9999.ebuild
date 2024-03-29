# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

FORTRAN_NEEDED=fortran

inherit conf-overlay cuda flag-o-matic fortran-2 git-r3 java-pkg-opt-2 toolchain-funcs multilib multilib-minimal snapshot

MY_UPDATE_PRRTE=

EGIT_REPO_URI="https://github.com/open-mpi/ompi.git"
EGIT_SUBMODULES=()

if [[ ${PV} == *9999 ]]; then
	KEYWORDS=""
else
	KEYWORDS="~amd64 ~amd64-linux ~ppc64 ~ppc64-linux"
fi

MY_P=${P/-mpi}
S=${WORKDIR}/${MY_P}

# TODO: --without-xpmem is not honored
IUSE_OPENMPI_FABRICS="
	openmpi_fabrics_knem
	openmpi_fabrics_ofi
	openmpi_fabrics_psm
	openmpi_fabrics_ucx
	openmpi_fabrics_ugni
	openmpi_fabrics_xpmem
	"

IUSE_OPENMPI_RM="
	openmpi_rm_alps
	openmpi_rm_lsf
	openmpi_rm_pbs
	openmpi_rm_slurm"

IUSE_OPENMPI_FS="
	openmpi_fs_gpfs
	openmpi_fs_ime
	openmpi_fs_pvfs2
	openmpi_fs_lustre
"

DESCRIPTION="A high-performance message passing library (MPI)"
HOMEPAGE="http://www.open-mpi.org"
LICENSE="BSD"
SLOT="0"
# TODO: ltdl: looks for nonexistant ltprtedl.h header
IUSE="+avx cma cray_xpmem cuda debug fortran heterogeneous ipv6 java ltdl +man
	mpi1 romio udreg
	${IUSE_OPENMPI_FABRICS} ${IUSE_OPENMPI_FS} ${IUSE_OPENMPI_RM}
	${IUSE_OPENMPI_OFED_FEATURES}"

REQUIRED_USE="
	openmpi_rm_slurm? ( !openmpi_rm_pbs )
	openmpi_rm_pbs? ( !openmpi_rm_slurm )
	cray_xpmem? ( openmpi_fabrics_xpmem )
	"

# TODO: check whether should depend on subslot of hwloc
CDEPEND="
	!sys-cluster/mpich
	!sys-cluster/mpich2
	!sys-cluster/nullmpi
	>=sys-cluster/pmix-4.0.0_pre:=
	>=sys-cluster/prrte-1
	>=dev-libs/libevent-2.0.22:=[${MULTILIB_USEDEP},threads]
	ltdl? ( dev-libs/libltdl:0[${MULTILIB_USEDEP}] )
	>=sys-apps/hwloc-2.0.2[${MULTILIB_USEDEP}]
	>=sys-libs/zlib-1.2.8-r1[${MULTILIB_USEDEP}]
	cuda? ( >=dev-util/nvidia-cuda-toolkit-6.5.19-r1:= )
	udreg? ( sys-cluster/cray-libs )
	openmpi_fabrics_knem? ( sys-cluster/knem )
	openmpi_fabrics_ofi? ( sys-fabric/libfabric )
	openmpi_fabrics_psm? ( sys-fabric/infinipath-psm:* )
	openmpi_fabrics_ucx? ( sys-cluster/ucx:= )
	openmpi_fabrics_ugni? ( sys-cluster/cray-libs )
	openmpi_fabrics_xpmem? ( cray_xpmem? ( sys-cluster/cray-libs ) )
	openmpi_rm_pbs? ( sys-cluster/torque )
	openmpi_rm_alps? ( sys-cluster/cray-libs )
	"

RDEPEND="${CDEPEND}
	java? ( >=virtual/jre-1.6 )"

DEPEND="${CDEPEND}
	java? ( >=virtual/jdk-1.6 )
	man? ( app-text/pandoc )"

PATCHES=(
	"${FILESDIR}"/${PN}-5-autogen-disabled-submodules.patch
	"${FILESDIR}"/${PN}-5-autogen-forward-args.patch
	"${FILESDIR}"/${PN}-5-autogen-default-to-shared-btl-ugni.patch
	"${FILESDIR}"/${PN}-5-rte-check-argc.patch
	"${FILESDIR}"/${PN}-5-pml-ob1-assert.patch
)

if ver_test  -ge "5.1.0.20210401.182437_pre"
then
	PATCHES+=("${FILESDIR}"/${PN}-5-autogen-fix-enable-mca-dso-arg.patch)
elif ver_test -lt "5.1.0.20210326.141212_pre"
then
	PATCHES+=("${FILESDIR}"/${PN}-5-autogen-build-Fix-typo-that-disabled-shared-components.patch)
fi

CONF_OVERLAY_FILES=(
	"etc/openmpi-mca-params.conf"
)

# TODO: this wrapping unexpectedly happens with no-multilib profile
# See report here: https://archives.gentoo.org/gentoo-user/message/c064b42a85f52758e3c5a46fd4fe37eb
# And, the wrapper doesn't work with 'clang -target le64-uknown-unknown-unknown' which
# is being used by dev-lang/halide. Workaround: disable wrapping.
#MULTILIB_WRAPPED_HEADERS=(
#	/usr/include/mpi.h
#	/usr/include/openmpi/ompi/mpi/java/mpiJava.h
#)

# Be verbose when executing important commands
my_vrun() {
	echo "$@"
	"$@" || die
}

pkg_setup() {
	fortran-2_pkg_setup
	java-pkg-opt-2_pkg_setup

	elog
	elog "OpenMPI has an overwhelming count of configuration options."
	elog "Don't forget the EXTRA_ECONF environment variable can let you"
	elog "specify configure options if you find them necessary."
	elog
}

my_get_submodule_url()
{
	sed -ne "/submodule \"$1\"/,\$ p" -e '/^\s*url\s*=/q' .gitmodules \
		| sed -ne 's/^\s*url\s*=\s*\(.*\)\s*/\1/p'
}

src_prepare() {
	default

	# Necessary for scalibility, see
	# http://www.open-mpi.org/community/lists/users/2008/09/6514.php
	echo 'oob_tcp_listen_mode = listen_thread' \
		>> opal/etc/openmpi-mca-params.conf || die

	local submodules=()
	local excluded_pkgs="libevent,hwloc,prrte,pmix"

	# TODO: somehow git-r3 checks out the submodules, but
	# git submodule status shows them with a '-' so check fails
	if [[ "${#submodules[@]}" -gt 0 ]]; then
		my_vrun git submodule init -- ${submodules[@]}
	fi

	my_vrun ./autogen.pl --no-3rdparty "${excluded_pkgs}"
}

my_join() {
	local IFS="$1"; shift; echo "$*";
}

multilib_src_configure() {
	if use java; then
		# We must always build with the right -source and -target
		# flags. Passing flags to javac isn't explicitly supported here
		# but we can cheat by overriding the configure test for javac.
		export ac_cv_path_JAVAC="$(java-pkg_get-javac) $(java-pkg_javac-args)"
	fi

	local excluded_components=""
	use avx || excluded_components="op-avx"

	local host_ldflags
	local conf_flags=()

	# TODO: if libfabric has gni use flag, it is linked against cray
	# libs that live outside of EPREFIX, so when ./configure tests
	# linking against libfabric, linker fails; so add -rpath-link ld
	# arg. It's a libfabric ebuild problem: try fiddle with 'rpath'?
	if use openmpi_fabrics_ofi; then
		local gni_libs=(cray-ugni cray-xpmem cray-alpsutil cray-alpslli
				cray-udreg cray-wlm_detect)
		$(tc-getPKG_CONFIG) --exists ${gni_libs[@]} || die
		host_ldflags+="$($(tc-getPKG_CONFIG) \
			--libs-only-L ${gni_libs[@]} \
			| sed 's/-L\(\S\+\)/-Wl,-rpath-link -Wl,\1/g')"
	fi

	# These components need to be built as shared libs because they depend
	# on external shared libs and we don't want a direct dependency on
	# those external libs from all binaries (e.g. mpicc). See PRRTE #871.
	local dso_components=(
		$(usex openmpi_fabrics_ugni btl-ugni)
		$(usex udreg rcache-udreg)
	)
	if use openmpi_fabrics_xpmem && use cray_xpmem; then
		dso_components+=(btl-sm)
	fi
	local enable_mca_dso=""
	if [[ "${#dso_components[@]}" -gt 0 ]]; then
		enable_mca_dso=--enable-mca-dso="$(my_join , ${dso_components[@]})"
	fi

	unset F77 FFLAGS # configure warns that unused, FC, FCFLAGS is used

	local final_ldflags
	if [[ -n "${drop_ldflags}" ]]; then
		final_ldflags="${host_ldflags}"
	else
		final_ldflags="${LDFLAGS} ${host_ldflags}"
	fi
	echo LDFLAGS="${final_ldflags}"
	export LDFLAGS="${final_ldflags}"
	ECONF_SOURCE=${S} econf \
		${enable_mca_dso} \
		--enable-pretty-print-stacktrace \
		--enable-mca-no-build="${excluded_components}" \
		--with-hwloc="${EPREFIX}/usr" \
		--with-hwloc-libdir="${EPREFIX}/usr/$(get_libdir)" \
		--with-libevent="${EPREFIX}/usr" \
		--with-libevent-libdir="${EPREFIX}/usr/$(get_libdir)" \
		--enable-mpi-fortran=$(usex fortran all no) \
		$(use_with ltdl libltdl "${EPREFIX}/usr") \
		$(use_with cma) \
		$(multilib_native_use_with cuda cuda "${EPREFIX}"/opt/cuda) \
		$(use_enable debug) \
		$(use_enable mpi1 mpi1-compatibility) \
		$(use_enable romio io-romio) \
		$(use_enable heterogeneous) \
		$(use_enable ipv6) \
		$(use_enable man man-pages) \
		--with-pmix="${EPREFIX}/usr" \
		--with-prrte="${EPREFIX}/usr" \
		$(multilib_native_use_enable java mpi-java) \
		$(multilib_native_use_with openmpi_fs_gpfs gpfs /usr) \
		$(multilib_native_use_with openmpi_fs_ime ime /usr) \
		$(multilib_native_use_with openmpi_fs_lustre lustre /usr) \
		$(multilib_native_use_with openmpi_fs_pvfs2 pvfs2 /usr) \
		$(multilib_native_use_with openmpi_fabrics_knem knem "${EPREFIX}"/usr) \
		$(multilib_native_use_with openmpi_fabrics_ofi ofi "${EPREFIX}"/usr) \
		$(multilib_native_use_with openmpi_fabrics_psm psm2 "${EPREFIX}"/usr) \
		$(multilib_native_use_with openmpi_fabrics_ucx ucx "${EPREFIX}"/usr) \
		$(multilib_native_use_with openmpi_fabrics_ucx ucx-libdir "${EPREFIX}"/usr/$(get_libdir)) \
		$(multilib_native_use_with openmpi_fabrics_ugni ugni) \
		$(multilib_native_use_with openmpi_fabrics_xpmem xpmem) \
		$(multilib_native_use_with cray_xpmem cray-xpmem) \
		$(multilib_native_use_with udreg udreg) \
		${conf_flags[@]}
}

multilib_src_compile() {
	emake V=1 "$@"
}

multilib_src_test() {
	# Doesn't work with the default src_test as the dry run (-n) fails.
	emake -j1 check
}

multilib_src_install() {
	default

	# fortran header cannot be wrapped (bug #540508), workaround part 1
	if multilib_is_native_abi && use fortran; then
		mkdir -p "${T}"/fortran || die
		mv "${ED}"/usr/include/mpif* "${T}"/fortran || die
	else
		# some fortran files get installed unconditionally
		rm \
			"${ED}"/usr/include/mpif* \
			"${ED}"/usr/bin/mpif* \
			|| die
	fi
}

multilib_src_install_all() {
	# fortran header cannot be wrapped (bug #540508), workaround part 2
	if use fortran; then
		mv "${T}"/fortran/mpif* "${ED}"/usr/include || die
	fi

	# Remove la files, no static libs are installed and we have pkg-config
	find "${ED}" -name '*.la' -delete || die

	if use java; then
		local mpi_jar="${ED}"/usr/$(get_libdir)/mpi.jar
		java-pkg_dojar "${mpi_jar}"
		# We don't want to install the jar file twice
		# so let's clean after ourselves.
		rm "${mpi_jar}" || die
	fi
	einstalldocs
	conf-overlay_src_install
}

src_install() {
	multilib-minimal_src_install
	snapshot_src_install
}
