// @ts-check

const { releaseVersionGenerator } = require('@nx/js/src/generators/release-version/release-version');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { REPO_ROOT } = require('../../scripts/consts');

/**
 * @returns {Promise<string[]>}
 */
async function runSetVersion() {
  const rnmPkgJson = require.resolve('react-native-macos/package.json');
  const { updateReactNativeArtifacts } = require('../../scripts/releases/set-rn-artifacts-version');

  const manifest = fs.readFileSync(rnmPkgJson, { encoding: 'utf-8' });
  const { version } = JSON.parse(manifest);

  await updateReactNativeArtifacts(version);

  spawnSync('yarn', ['install', '--mode', 'update-lockfile']);

  return [
    path.join(
      REPO_ROOT,
      'packages',
      'react-native',
      'ReactAndroid',
      'gradle.properties',
    ),
    path.join(
      REPO_ROOT,
      'packages',
      'react-native',
      'ReactAndroid',
      'src',
      'main',
      'java',
      'com',
      'facebook',
      'react',
      'modules',
      'systeminfo',
      'ReactNativeVersion.java',
    ),
    path.join(REPO_ROOT,
      'packages',
      'react-native',
      'React',
      'Base',
      'RCTVersion.m',
    ),
    path.join(
      REPO_ROOT,
      'packages',
      'react-native',
      'ReactCommon',
      'cxxreact',
      'ReactNativeVersion.h',
    ),
    path.join(
      REPO_ROOT,
      'packages',
      'react-native',
      'Libraries',
      'Core',
      'ReactNativeVersion.js',
    ),
    path.join(
      REPO_ROOT,
      'yarn.lock',
    ),
  ];
}

/** @type {typeof releaseVersionGenerator} */
module.exports = async function(tree, options) {
  const { data, callback } = await releaseVersionGenerator(tree, options);
  return {
    data,
    callback: async (tree, options) => {
      const result = await callback(tree, options);

      // Only update artifacts if there were changes
      const changedFiles = Array.isArray(result) ? result : result.changedFiles;
      if (changedFiles.length > 0) {
        fs.writeFile(path.join(REPO_ROOT, '.rnm-publish'), '', () => null);
        const versionedFiles = await runSetVersion();
        changedFiles.push(...versionedFiles);
      }

      return result;
    },
  };
};
