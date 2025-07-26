{{# if (isset($UBUNTU_REPO) && ($UBUNTU_REPO === 'old-releases')): }}

	### Enable "Old Ubuntu Releases" repo (source: <https://askubuntu.com/a/91821>)
	RUN sed -i -re 's/([a-z]{2}\.)?archive.ubuntu.com|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list
{{# endif }}

