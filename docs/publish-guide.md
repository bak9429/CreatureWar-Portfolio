# GitHub Public 저장소 게시 방법

이 ZIP은 공개 가능한 문서·CSV 샘플·정적 뷰어만 포함합니다. **원본 Unreal 소스/모델 파일/개인 경로는 포함하지 않습니다.**

## GitHub CLI로 한 번에 게시 (권장)

1. ZIP을 해제하고 `CreatureWar-Portfolio` 폴더 안의 `PUBLISH_PUBLIC.bat`를 실행합니다.
2. GitHub CLI(`gh`)와 Git이 설치되어 있어야 합니다. 미설치 시 [GitHub CLI](https://cli.github.com/) 및 [Git](https://git-scm.com/downloads/win)을 설치합니다.
3. `gh auth login`으로 로그인합니다. ChatGPT의 GitHub 연결과 PC 로컬 CLI 로그인은 별도입니다.
4. Git의 작성자 이름과 이메일이 미설정 상태라면 `git config --global user.name "표시할 이름"` 및 `git config --global user.email "이메일"`을 설정합니다. 공개 노출을 원하지 않으면 GitHub의 **noreply 이메일**을 사용할 수 있습니다.
5. 공개 안내 및 업로드 파일을 확인한 후 `PUBLISH`라고 입력하면 Public 저장소를 생성하고 푸시합니다.

## 수동 게시

1. GitHub의 [새 저장소 만들기](https://github.com/new)에서 `CreatureWar-Portfolio`, **Public**, 빈 저장소를 만듭니다.
2. 이 폴더에서 PowerShell을 엽니다.
3. 아래 명령에서 `YOUR_ACCOUNT`를 계정명으로 바꿉니다.

```powershell
git init -b main
git add .
git commit -m "docs: publish Creature War portfolio"
git remote add origin https://github.com/YOUR_ACCOUNT/CreatureWar-Portfolio.git
git push -u origin main
```

## 정적 데모 활성화(선택)

Repository → Settings → Pages → Deploy from a branch → `main` / `/(root)` → Save. 이후 `https://YOUR_ACCOUNT.github.io/CreatureWar-Portfolio/` 형식으로 뷰어를 공개할 수 있습니다.

## 중요

- 업로드 전 저장소가 **Public**인지 다시 확인하세요.
- 원본 Unreal 프로젝트 폴더에서 이 명령을 실행하지 마세요. 오직 이 공개용 폴더만 업로드해야 합니다.
- 기존 GitHub 저장소 이름이 중복되면 새로운 저장소를 임의 덮어쓰지 않고 스크립트가 중단됩니다.
- 검증되지 않은 GLB/AI 이미지나 모델 가중치를 별도로 추가하지 마세요.
