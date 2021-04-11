# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: snapshot.eclass
# @MAINTAINER:
# Alexei Colin <ac@alexeicolin.com>
# @SUPPORTED_EAPIS: 4 5 6 7
# @BLURB:Fetch specific snapshot versions from VCS.
# @DESCRIPTION
# Supports fetching specific commit from VCS based on package version.
# of the form 1.0.YYYYMMDD[.hhmmss]_(pre|p), where the version in
# front can be any version of any length, and _p suffix signifies the given
# release plus commits up to timestamp, and _pre signifies unreleased (next)
# version plus commits up to the timestamp. This convention should be enough to
# distinguish from upstream release versions which might also make use of the
# _p and _pre suffixes, and from the live versions that end with 9999.
#
# The timestamp is given to git as YYYY-MM-DDThh:mm:ss+0000 (i.e. UTC
# timezone). If hhmmss version component is ommitted, then it the timestamp
# is YYYY-MM-DDT00:00:00+0000. This keeps the resolution of timestamp into
# commit hash deterministic (as long as you never pick a date that's in the
# future), since it's unclear exactly how git interprets `--before=YYYY-MM-DD`
# without a time.
#
# To view the git history with dates usable as snapshots timestamps:
# 	TZ=UTC git log --date=iso8601-local
#
# To check what commit a timestamp corresponds to use:
# 	git rev-list HEAD --first-parent --max-count 1 \
#		--before=YYYY-MM-DDThh:mm:ss+0000

EXPORT_FUNCTIONS src_install

inherit git-r3

# @FUNCTION snapshot_to_iso_date
# @USAGE: [version]
# @DESCRIPTION: Resolve a version with a timestamp into date in ISO-8601 format.
# If version argument is not given, PV is used as the default.
# If version is not recognized as containing a snapshot (see eclass description
# above), then return value is empty.
# Transforms: 1.0.YYYYMMDD[.hhmmss]_(p|pre) -> YYYY-MM-DDThh:mm:ss+0000
snapshot_to_iso_date() {
	local ver="${1:-${PV}}"
	local n=1
	while [[ -n "$(ver_cut "${n}" "${ver}")" ]]; do
		n=$((n+1))
	done
	n=$((n-1))

	if [[ ! ( "${n}" -gt 2 && "$(ver_cut ${n} ${ver})" =~ ^(p|pre)$ ) ]]
	then
		return # not a snapshot version so return blank
	fi

	local ts_date ts_time
	if [[ "$(ver_cut $((n-2))-$((n-1)) ${ver})" =~ ^[0-9]{8}\.[0-9]{6}$ ]]
	then
		ts_date="$(ver_cut $((n-2)) ${ver})"
		ts_time="$(ver_cut $((n-1)) ${ver})"
	elif [[ "$(ver_cut $((n-1)) ${ver})" =~ ^[0-9]{8}$ ]]
	then
		ts_date="$(ver_cut $((n-1)) ${ver})"
		ts_time="000000"
	else
		die "failed to parse YYYYMMDD[.hhmmss] timestamp from ${ver}"
	fi

	local ts_year="${ts_date:0:4}"
	local ts_month="${ts_date:4:2}"
	local ts_day="${ts_date:6:2}"
	( [[ ! ( 1 -le "${ts_month#0}" && "${ts_month#0}" -ge 12 ) ]] && \
	  [[ ! ( 1 -le "${ts_day#0}" && "${ts_day#0}" -ge 31 ) ]] ) || \
		die "invalid date in ${ver} (expected YYYYMMDD)"

	local ts_hour="${ts_time:0:2}"
	local ts_min="${ts_time:2:2}"
	local ts_sec="${ts_time:4:2}"
	( [[ ! ( 0 -le "${ts_hour#0}" && "${ts_hour#0}" -ge 23 ) ]] && \
	  [[ ! ( 0 -le "${ts_min#0}" && "${ts_him#0}" -ge 59 ) ]] &&
	  [[ ! ( 0 -le "${ts_sec#0}" && "${ts_sec#0}" -ge 59 ) ]] ) || \
		die "invalid time in ${ver} (expected hhmmss)"

	local iso_date="${ts_year}-${ts_month}-${ts_day}"
	local iso_time="${ts_hour}:${ts_min}:${ts_sec}"
	echo "${iso_date}T${iso_time}+0000"
}

snapshot_src_install() {
	local snapshot_dir="${ED}"/etc/snapshot/${CATEGORY}
	mkdir -p "${snapshot_dir}" || die
	git -C "${S}" rev-parse HEAD > "${snapshot_dir}"/${PN} || die
}

EGIT_COMMIT_DATE="$(snapshot_to_iso_date)"
