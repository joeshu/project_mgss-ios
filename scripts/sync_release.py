import json
import os
import pathlib
import subprocess
import urllib.parse

repo = os.environ['GITHUB_REPOSITORY']
token = os.environ['GITHUB_TOKEN']
tag = os.environ.get('TAG_NAME', 'ci-main-latest')
name = os.environ.get('RELEASE_NAME', tag)
ipa = pathlib.Path(os.environ['IPA_PATH'])
body = (
    'Auto-synced unsigned IPA from main branch CI.\n\n'
    f'- workflow: {os.environ.get("GITHUB_WORKFLOW", "")}\n'
    f'- run: https://github.com/{repo}/actions/runs/{os.environ.get("GITHUB_RUN_ID", "")}\n'
    f'- commit: {os.environ.get("GITHUB_SHA", "")}\n'
)

def bearer_header(tok: str) -> str:
    return ''.join(['Authorization', ': ', 'Bearer', ' ', tok])

def curl_json(method, url, data=None, extra_headers=None, binary_file=None):
    cmd = [
        'curl', '-fsS', '-X', method,
        '-H', 'Accept: application/vnd.github+json',
        '-H', 'X-GitHub-Api-Version: 2022-11-28',
        '-H', bearer_header(token),
    ]
    if extra_headers:
        for h in extra_headers:
            cmd += ['-H', h]
    if binary_file:
        cmd += ['--data-binary', '@' + binary_file]
    elif data is not None:
        cmd += ['--data-binary', json.dumps(data)]
    cmd.append(url)
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if p.returncode:
        raise RuntimeError((p.stderr or p.stdout).strip())
    return json.loads(p.stdout or '{}')

base = f'https://api.github.com/repos/{repo}'
auth_header = bearer_header(token)
check = subprocess.run([
    'curl', '-sS', '-o', '/tmp/release_check.json', '-w', '%{http_code}',
    '-H', 'Accept: application/vnd.github+json',
    '-H', auth_header,
    f'{base}/releases/tags/{tag}'
], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
if check.returncode:
    raise RuntimeError((check.stderr or check.stdout).strip())
status = check.stdout.strip()
release_payload = {
    'tag_name': tag,
    'target_commitish': 'main',
    'name': name,
    'body': body,
    'draft': False,
    'prerelease': False,
    'generate_release_notes': False,
}
if status == '200':
    existing = json.loads(pathlib.Path('/tmp/release_check.json').read_text() or '{}')
    release_id = existing['id']
    release = curl_json('PATCH', f'{base}/releases/{release_id}', data=release_payload)
else:
    release = curl_json('POST', f'{base}/releases', data=release_payload)

release_id = release['id']
asset_name = ipa.name
for asset in release.get('assets', []):
    if asset.get('name') == asset_name:
        subprocess.run([
            'curl', '-fsS', '-X', 'DELETE',
            '-H', auth_header,
            '-H', 'Accept: application/vnd.github+json',
            f'{base}/releases/assets/{asset["id"]}'
        ], check=True)

upload_url = (
    f'https://uploads.github.com/repos/{repo}/releases/{release_id}/assets'
    f'?name={urllib.parse.quote(asset_name)}'
)
asset = curl_json(
    'POST',
    upload_url,
    extra_headers=['Content-Type: application/octet-stream'],
    binary_file=str(ipa),
)
print(json.dumps({
    'release_url': release.get('html_url'),
    'asset_url': asset.get('browser_download_url')
}, ensure_ascii=False))
