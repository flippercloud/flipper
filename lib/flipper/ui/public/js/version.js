// Get the latest release from RubyGems.org and show a badge if it's not the current version
function checkLatestRelease() {
  // Skip check if last check was less than 1 day ago
  if(localStorage.getItem('flipper.releaseCheckedAt') > new Date().getTime() - 86400000) return

  // store the last time we checked for a new version
  localStorage.setItem('flipper.releaseCheckedAt', new Date().getTime())

  fetch('https://www.flippercloud.io/release.json').then(response => {
    // Something went wrong, so just give up
    if(!response.ok) return

    response.json().then(release => {
      localStorage.setItem('flipper.release', JSON.stringify(release))
      showReleaseBadge()
    })
  })
}

// Show a badge if a new release is available
function showReleaseBadge() {
  const badge = document.querySelector('#new-version-badge')
  const release = JSON.parse(localStorage.getItem('flipper.release') || false)

  if(!badge || !release || badge.dataset.version === release.version) return

  badge.innerText = `${release.version} available!`
  badge.setAttribute('href', release.changelog_uri)
  badge.classList.remove('d-none')
}

checkLatestRelease()
showReleaseBadge()
