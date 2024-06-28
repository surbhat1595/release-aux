import subprocess
import os

# List of packages and their corresponding repositories
package_repo_map = {
    'percona-toolkit': ['pt', 'pdps', 'pdpxc'],
    'percona-xtrabackup-24': ['pxb-24', 'pdps', 'pdpxc'],
    'percona-xtrabackup-80': ['pxb-80', 'pdps', 'pdpxc'],
    'percona-xtrabackup-81': ['pxb-8x-innovation', 'pdps', 'pdpxc'],
    'percona-xtrabackup-82': ['pxb-8x-innovation', 'pdps', 'pdpxc'],
    'percona-xtrabackup-83': ['pxb-8x-innovation', 'pdps', 'pdpxc'],
    'pmm2-client': ['pmm2-client'],
    'proxysql2': ['proxysql', 'pdpxc'],
    'sysbench': ['sysbench'],
    'percona-backup-mongodb': ['pbm', 'pdmdb'],
}

# Corresponding repository base URLs for verification
repository_base_urls = {
    'pt': 'http://repo.percona.com/pt/apt',
    'pxb-24': 'http://repo.percona.com/pxb-24/apt',
    'pxb-80': 'http://repo.percona.com/pxb-80/apt',
    'pxb-8x-innovation': 'http://repo.percona.com/pxb-8x-innovation/apt',
    'pmm2-client': 'http://repo.percona.com/pmm2-client/apt',
    'proxysql': 'http://repo.percona.com/proxysql/apt',
    'sysbench': 'http://repo.percona.com/sysbench/apt',
    'pbm': 'http://repo.percona.com/pbm/apt',
    'pdps': 'http://repo.percona.com/pdps',
    'pdpxc': 'http://repo.percona.com/pdpxc',
    'pdmdb': 'http://repo.percona.com/pdmdb',
}

# Corresponding repository base URLs for RPM-based systems
repository_base_urls_rpm = {
    'percona': 'http://repo.percona.com/percona/yum',
    'original': 'http://repo.percona.com/release/yum',
    'tools': 'http://repo.percona.com/tools/yum',
}

# Function to get the list of installed packages for Debian-based systems
def get_installed_packages_deb():
    try:
        installed_packages = subprocess.check_output(['dpkg-query', '-W', '-f=${binary:Package}\n']).decode().splitlines()
        return installed_packages
    except subprocess.CalledProcessError as e:
        print(f"Error getting installed packages: {e}")
        return []

# Function to get the repository URL of a package for Debian-based systems
def get_package_repository_url_deb(package):
    try:
        show_output = subprocess.check_output(['apt-cache', 'policy', package]).decode().splitlines()
        for line in show_output:
            if 'http' in line or 'https' in line:
                repo_url = line.strip().split()[1]
                return repo_url
    except subprocess.CalledProcessError as e:
        print(f"Error getting policy info for package {package}: {e}")
    return None

# Function to check if a repository is enabled for Debian-based systems
def is_repo_enabled_deb(repo_keyword):
    try:
        sources_list = subprocess.check_output(['grep', '-rhE', '^[^#]', '/etc/apt/sources.list', '/etc/apt/sources.list.d/']).decode().splitlines()
        for line in sources_list:
            if repo_keyword in line:
                return True
    except subprocess.CalledProcessError as e:
        print(f"Error checking if repository {repo_keyword} is enabled: {e}")
    return False

# Function to get the list of installed packages for RPM-based systems
def get_installed_packages_rpm():
    try:
        installed_packages = subprocess.check_output(['rpm', '-qa', '--qf', '%{NAME}\n']).decode().splitlines()
        return installed_packages
    except subprocess.CalledProcessError as e:
        print(f"Error getting installed packages: {e}")
        return []

# Function to get the repository URL of a package for RPM-based systems
def get_package_repository_url_rpm(package):
    try:
        show_output = subprocess.check_output(['yum', 'info', package]).decode().splitlines()
        for line in show_output:
            if 'From repo' in line:
                repo_name = line.split(':')[1].strip()
                repo_url = f"http://repo.percona.com/{repo_name}/yum"
                return repo_url
    except subprocess.CalledProcessError as e:
        print(f"Error getting repository info for package {package}: {e}")
    return None

# Function to match repository URL with wildcard for Debian-based systems
def match_repo_url_with_wildcard(repo_url, expected_repo_url):
    return repo_url.startswith(expected_repo_url)

# Function to check if the package is installed from the correct repository for RPM-based systems
def check_package_repository_rpm(package, repo_keyword):
    repo_url = get_package_repository_url_rpm(package)
    if repo_url:
        expected_repo_url = repository_base_urls_rpm.get(repo_keyword)
        if expected_repo_url and repo_url.startswith(expected_repo_url):
            return True
    return False

# Function to determine the distribution
def get_distro():
    try:
        with open("/etc/os-release") as f:
            for line in f:
                if line.startswith("ID="):
                    return line.strip().split("=")[1].strip('"')
    except Exception as e:
        print(f"Error determining the distribution: {e}")
    return None

# Function to enable repositories
def enable_repositories(repos_to_enable):
    enabled_repos = []
    for repo in repos_to_enable:
        if repo not in {'pdps', 'pdpxc', 'pdmdb'}:
            command = f"sudo percona-release enable {repo} release"
            try:
                subprocess.run(command, shell=True, check=True)
                enabled_repos.append(repo)
            except subprocess.CalledProcessError as e:
                print(f"Error enabling repository {repo}: {e}")
    return enabled_repos

# Main script
if __name__ == "__main__":
    distro = get_distro()
    if distro in ['ubuntu', 'debian']:
        print("Checking installed packages and repositories for Debian-based system...\n")
        installed_packages = get_installed_packages_deb()
        get_package_repository_url = get_package_repository_url_deb
        is_repo_enabled = is_repo_enabled_deb
    elif distro in ['centos', 'rhel', 'ol']:
        print("Checking installed packages and repositories for RPM-based system...\n")
        installed_packages = get_installed_packages_rpm()
        get_package_repository_url = get_package_repository_url_rpm
    else:
        print("Unsupported Linux distribution")
        exit(1)
    
    packages_from_target_repos = []
    suggested_repos = []
    repos_to_enable = set()
    exclude_repos = {'pdps', 'pdpxc', 'pdmdb'}

    for package in installed_packages:
        if package in package_repo_map:
            repo_keywords = package_repo_map[package]
            repo_url = get_package_repository_url(package)
            valid_repo_found = False
            for repo_keyword in repo_keywords:
                if distro in ['ubuntu', 'debian']:
                    expected_repo_url = repository_base_urls[repo_keyword]
                    repo_enabled = is_repo_enabled(repo_keyword)
                    if repo_url and match_repo_url_with_wildcard(repo_url, expected_repo_url) and repo_enabled:
                        packages_from_target_repos.append((package, repo_keyword))
                        valid_repo_found = True
                        break
                elif distro in ['centos', 'rhel', 'ol']:
                    if check_package_repository_rpm(package, repo_keyword):
                        packages_from_target_repos.append((package, repo_keyword))
                        valid_repo_found = True
                        break
            if not valid_repo_found:
                suggested_repos.append((package, repo_keywords))
                repos_to_enable.update(repo_keywords)

    print("\nSummary:")
    if packages_from_target_repos:
        print(f"  - {len(packages_from_target_repos)} packages are installed from the correct repositories.")
    if suggested_repos:
        print(f"  - {len(suggested_repos)} packages should be installed from a different repository.")
        print(f"  - {len(repos_to_enable - exclude_repos)} repositories need to be enabled.")
    else:
        print("  - All packages are installed from their correct repositories.")

    if suggested_repos:
        print("\nPackages that should be installed from a different repository:")
        for pkg, repos in suggested_repos:
            print(f"  - {pkg}")
            print(f"    Possible repositories: {', '.join([repo for repo in repos if repo not in exclude_repos])}")

        print("\nTo enable the necessary repositories, run the following commands:")
        for repo in repos_to_enable:
            if repo not in exclude_repos:
                print(f"  sudo percona-release enable {repo} release")

        # Ask the user if they want to enable the suggested repositories
        user_input = input("\nWould you like to enable all the mentioned repositories? (yes/no): ").strip().lower()
        if user_input in {'yes', 'y'}:
            enabled_repos = enable_repositories(repos_to_enable)
            if enabled_repos:
                print("\nThe following repositories were enabled:")
                for repo in enabled_repos:
                    print(f"  - {repo}")
