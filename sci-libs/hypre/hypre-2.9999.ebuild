# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

EGIT_REPO_URI="https://github.com/hypre-space/hypre.git"
FORTRAN_NEEDED=fortran

inherit autotools fortran-2 toolchain-funcs flag-o-matic git-r3 snapshot

DESCRIPTION="Parallel matrix preconditioners library"
HOMEPAGE="https://computation.llnl.gov/projects/hypre-scalable-linear-solvers-multigrid-methods"

LICENSE="LGPL-2.1"
SLOT="0/$(ver_cut 1-3)"

if [[ ${PV} == *9999 ]]
then
	KEYWORDS=""
else
	KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux"
fi

# Type and precision settings
IUSE_HYPRE_TYPE="
	hypre_type_bigint
	hypre_type_complex
	hypre_type_single
	hypre_type_longdouble
"
# Portability layers
IUSE_HYPRE_PORT="
	hypre_port_kokkos
	hypre_port_raja
"
# Memory types for which to use the Umpire memory allocator
IUSE_HYPRE_UMPIRE="
	hypre_umpire_host
	hypre_umpire_device
	hypre_umpire_pinned
	hypre_umpire_um
"
IUSE_HYPRE_DEVICE="
	hypre_device_openmp
	hypre_device_hip
	hypre_device_cuda
"
# GPU-accelerated libraries and features to use with AMD GPUs
IUSE_HYPRE_HIP="
	hypre_hip_sparse
	hypre_hip_blas
	hypre_hip_rand
"
# GPU-accelerated libraries and features to use with nVidia GPUs
IUSE_HYPRE_CUDA="
	hypre_cuda_blas
	hypre_cuda_cub
	hypre_cuda_sparse
	hypre_cuda_streams
	hypre_cuda_rand
"

IUSE="debug examples fortran hopscotch mli persistent mpi unified-memory openmp
	node-aware-mpi gpu-aware-mpi
	caliper gpu-profiling timing memory-tracker
	${IUSE_HYPRE_TYPE} ${IUSE_HYPRE_PORT}
	umpire ${IUSE_HYPRE_UMPIRE}
	${IUSE_HYPRE_DEVICE} ${IUSE_HYPRE_CUDA} ${IUSE_HYPRE_HIP}
	"

REQUIRED_USE="
	?? ( ${IUSE_HYPRE_TYPE} )
	?? ( ${IUSE_HYPRE_PORT} )
	?? ( ${IUSE_HYPRE_DEVICE} )
	hopscotch? ( openmp )
	hypre_device_cuda? ( unified-memory )
	unified-memory? ( || ( ${IUSE_HYPRE_DEVICE} ) )
	hypre_device_openmp? ( openmp )
	gpu-aware-mpi? ( mpi )
	node-aware-mpi? ( mpi )
"

# TODO: unpackaged: raja umpire dsuperlu
# TODO: deps for roc raja umpire
BDEPEND="virtual/pkgconfig"
RDEPEND="
	sci-libs/superlu:=
	virtual/blas
	virtual/lapack
	caliper? ( dev-libs/caliper )
	hypre_device_cuda? ( dev-util/nvidia-cuda-toolkit[profiler] )
	hypre_port_kokkos? ( dev-cpp/kokkos )
	mpi? ( virtual/mpi )
"
DEPEND="${RDEPEND}"

PATCHES=(
	# Either remove the include, or require profiler use flag in cuda
	#"${FILESDIR}"/${PN}-2.20.0-cuda-remove-profiler-include.patch
	"${FILESDIR}"/${PN}-2.20.0-reinstall.patch
	"${FILESDIR}"/${PN}-2.20.0-vector-load.patch
	"${FILESDIR}"/${PN}-2.20.0-disable-prefetch.patch
)

DOCS=( CHANGELOG COPYRIGHT README )

pkg_pretend() {
	if [[ ${MERGE_TYPE} != binary ]] && use openmp && [[ $(tc-getCC) == *gcc* ]] ; then
		tc-check-openmp
	fi
}

pkg_setup() {
	if [[ ${MERGE_TYPE} != binary ]] && use openmp && [[ $(tc-getCC) == *gcc* ]] && ! tc-has-openmp ; then
		ewarn "You are using a non capable gcc compiler ( < 4.2 ? )"
		die "Need an OpenMP capable compiler"
	fi
}

src_prepare() {
	default

	# Needed only because we patched configure.in
	pushd src || die
	./config/bootstrap || die
	popd || die

	# link with system superlu and propagate LDFLAGS
	sed -e "s:@LIBS@:@LIBS@ $($(tc-getPKG_CONFIG) --libs superlu):" \
		-i src/config/Makefile.config.in || die

	sed -e '/HYPRE_ARCH/s: = :=:g' \
		-i src/configure || die

	# link with system blas and lapack
	sed -e '/^BLASFILES/d' \
		-e '/^LAPACKFILES/d' \
		-i src/lib/Makefile || die
}

src_configure() {
	tc-export CC CXX
	append-flags -Dhypre_dgesvd=dgesvd_

	if use openmp && [[ $(tc-getCC) == *gcc* ]] ; then
		append-flags -fopenmp && append-ldflags -fopenmp
	fi

	if use mpi ; then
		CC=mpicc
		FC=mpif77
		CXX=mpicxx
	fi

	cd src || die

	if use hypre_device_cuda; then
		export CUDA_HOME=${EPREFIX}/opt/cuda
		# HYPRE_CUDA_SM set via package.env (which comes from profile)
		# nvcc doesn't accept -Wl, (present in default linux profile)
		filter-flags -Wl,*
	fi
	econf \
		--enable-shared \
		--with-blas \
		--with-blas-libs="$($(tc-getPKG_CONFIG) --libs-only-l blas | sed -e 's/-l//g')" \
		--with-blas-lib-dirs="$($(tc-getPKG_CONFIG) --libs-only-L blas | sed -e 's/-L//g')" \
		--with-lapack \
		--with-lapack-libs="$($(tc-getPKG_CONFIG) --libs-only-l lapack | sed -e 's/-l//g')" \
		--with-lapack-lib-dirs="$($(tc-getPKG_CONFIG) --libs-only-L lapack | sed -e 's/-L//g')" \
		--with-superlu \
		--without-dsuperlu \
		$(use_enable debug) \
		$(use_enable hypre_type_bigint bigint) \
		$(use_enable hypre_type_complex complex) \
		$(use_enable hypre_type_longdouble longdouble) \
		$(use_enable hypre_type_single single) \
		$(use_enable fortran) \
		$(use_enable hopscotch) \
		$(use_enable persistent) \
		$(use_enable unified-memory) \
		$(use_enable gpu-profiling) \
		$(use_enable gpu-aware-mpi) \
		$(use_with hypre_device_cuda cuda) \
		$(use_enable hypre_cuda_streams cuda-streams) \
		$(use_enable hypre_cuda_sparse cusparse) \
		$(use_enable hypre_cuda_cub cub) \
		$(use_enable hypre_cuda_blas cublas) \
		$(use_enable hypre_cuda_rand curand) \
		$(use_with hypre_device_hip hip) \
		$(use_enable hypre_hip_sparse rocsparse) \
		$(use_enable hypre_hip_blas rocblas) \
		$(use_enable hypre_hip_rand rocrand) \
		$(use_with hypre_device_openmp device-openmp) \
		$(use_with hypre_port_kokkos kokkos) \
		$(use_with hypre_port_raja raja) \
		$(use_with caliper) \
		$(use_with memory-tracker) \
		$(use_with mli) \
		$(use_with openmp) \
		$(use_with mpi MPI) \
		$(use_with node-aware-mpi) \
		$(use_with timing)
}

src_compile() {
	emake -C src
}

src_test() {
	LD_LIBRARY_PATH="${S}/src/lib:${LD_LIBRARY_PATH}" \
				   PATH="${S}/src/test:${PATH}" \
				   emake -C src check
}

src_install() {
	local libdir=usr/$(get_libdir)
	local incdir=usr/include/${PN}
	emake -C src install \
		  HYPRE_INSTALL_DIR="${ED}" \
		  HYPRE_LIB_INSTALL="${ED}/${libdir}" \
		  HYPRE_INC_INSTALL="${ED}/${incdir}"

	local urls=(${HOMEPAGE})
	cat <<-EOF > ${PN}.pc
	Name: ${PN}
	Description: ${DESCRIPTION}
	Version: ${PV}
	URL: ${urls[0]}
	Libs: -lHYPRE
	Cflags: -I${EPREFIX}/${incdir}
	EOF

	insinto /usr/$(get_libdir)/pkgconfig
	doins ${PN}.pc

	if use examples; then
		dodoc -r src/examples
	fi
}
