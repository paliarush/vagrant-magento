Desired developer experience
----------------------------

Vagrant provides convenient way to set up development environment consistently on different hosts (see [more](https://docs.vagrantup.com/v2/why-vagrant/)). Typically it uses Virtual Box as a provider with \*nix system as guest OS.
This allows Magento developers who use Windows machines to run their Magento instance in \*nix environment similar to those on Bamboo or production.
Project files editing, work with Git and running tests is usually done on host OS (Windows), since this approach provides better user experience. However, in this case project files must be synchronized between host and guest OSs to allow code modifications be visible on the running Magento instance as well as provide access to auto-generated files (e.g. view materialized files, generated classes) in the IDE. So two-way synchronization is required.

Existing problem for Windows users
----------------------------------

Developers, who use Magento installed on Vagrant for daily development in Windows environment, complaint about Magento performance issues.
The main reason for performance degradation is that default synchronization (Virtual box shared folders) is used for project files synchronization on host and on guest OSs. **PHP requests all source files from the host,** as well a lot of files are created by the Magento instance on the fly in non-production mode, which are immediately synchronized with the host.
There are several other types of files synchronization available, but all of them have issues, which spoil developer experience:

 - SMB - on some machines does not work (various errors, unstable
   implementation). Also when EE is linked to CE on the host using
   symlinks (our current workflow), **symlinks are not created properly** on
   the guest. SSH connection to the guest OS is aborted from time to
   time when SMB is enabled. 
 - RSync - requires extra software to be installed on the Windows,
   provides **one-way synchronization only**
 - NFS - is recommended and performant option for \*nix hosts, but is
   **unavailable for Windows** hosts
   
Proposed solution
-----------------

Even though there are no out-of-the-box solution which satisfies our developer experience requirements, we can apply hybrid approach, which:

 - is reasonably complex
 - does not break developer experience
 - has negligible performance degradation caused by files synchronization

To solve performance degradation problem, local copy of the project should be stored on host (for good indexing performance in IDE) and on the guest (to avoid delays caused by PHP requesting remote files via network). This cannot be achieved with built-in Vagrant synchronization capabilities. However, this can be done using one-way PhpStorm project deployment to remote host or by using rsync.  This approach has one drawback: all files generated on the guest, will not be visible to IDE and as a result autocomplete for auto-generated classes will be unavailable. This issue can be overcome by enabling two-way Vagrant synchronization for those files which should be downloaded from guest OS.
