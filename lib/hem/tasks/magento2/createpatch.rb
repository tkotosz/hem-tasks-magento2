#!/usr/bin/env ruby
# ^ Syntax hint

desc 'Create magento2 patch'
task :createpatch do
  package_name = Hem.ui.ask("which package did you modify? (e.g. module-catalog)")
  patch_name = Hem.ui.ask("what should be the name of the patch? (e.g. my awesome fix )")
  patch_tmp_path = '/tmp/patchtmp/'
  package_path = 'vendor/magento/' + package_name

  if patch_name.empty?
    Kernel.abort('patch name required')
  end

  if package_name.empty?
    Kernel.abort('package name required')
  end

  if !File.exists?(package_path)
    Kernel.abort(package_path + ' does not exist')
  end

  Hem.ui.info('Patch will be created for ' + package_path)
  Hem.ui.info('1. Save your changes to ' + patch_tmp_path + package_name)
  FileUtils.rm_rf(patch_tmp_path)
  FileUtils.mkdir_p(patch_tmp_path)
  FileUtils.cp_r(package_path, patch_tmp_path)

  Hem.ui.info('2. Reinstall package')
  FileUtils.rm_rf(package_path)
  run_command('php bin/composer.phar install', realtime: true, indent: 2)

  Hem.ui.info('3. Init git with the original code of the package')
  FileUtils.cd(package_path)
  shell('git init')
  shell('git add .')
  shell('git commit -m "original code"')

  Hem.ui.info('4. Apply your changes')
  FileUtils.cp_r(patch_tmp_path + package_name + '/.', '.')

  Hem.ui.info('5. Create patch based on your changes')
  shell('git add .')
  shell('git commit -m "' + patch_name + '"')
  shell('git format-patch HEAD^..HEAD')

  Hem.ui.info('5. Move your patch to the project\'s patch directory')
  FileUtils.mv(Dir.glob('*.patch'), '../../../patches/')

  Hem.ui.info('6. Revert the changes in the package')
  shell('git reset --hard HEAD^1')
  FileUtils.rm_rf('.git')
  FileUtils.cd('../../../')

  Hem.ui.success('Patch created')
  Hem.ui.info('Please add the new patch to your project\'s composer.patches.json')
  Hem.ui.info('Please run composer install to see if you patch can be applied successfully')
end