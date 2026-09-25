#!/bin/bash
# BLOCK6 パスページを生成する。
# - 2000円ゲスト / イエロー (¥2,500→¥2,000)    : _template_discount.html → ${slug}/
# - 関係者 / ブルー (¥2,500→¥1,000)            : _template_artist.html   → ${slug}-sp/
# - フリー / ピンク (FREE・UEのみ)              : _template_free.html     → ${slug}-free/
# - ルート (案内+LINKS・パス本体なし・UEパスへのリンク): _template_discount.html から生成 → index.html
# URLは読めるスラッグ固定（例: /ue/ と /ue-sp/）。独自ドメイン block6.djue.me で公開。
# _template_artist.html / _template_free.html は _template_discount.html から派生生成する（正本は discount 側）。
# チケットの地色は受付で渡すリストバンドの色と同期させている（イエロー/ブルー/ピンク。当日客=グリーンはバンドのみ）。

set -euo pipefail

cd "$(dirname "$0")"

BASE_URL="https://block6.djue.me"

# GA4 測定ID。digtracks プロパティ (319283938) に相乗り。
# レポート時は hostname = block6.djue.me で絞る（page_title に DJ 名とパス種別が入る）。
GA4_ID="G-4N9ENSKWVH"

# "表示名|スラッグ"
DJS=("UE|ue" "P-KI|pki" "FUMIYA|fumiya" "なおと↯まふぃあ|naoto" "FU-SE|fuse" "yunkmr|yunkmr" "YUUKI|yuuki" "KAZUKI|kazuki" "KOUICHI|kouichi")
FREE_DJS=("UE|ue")
# ディスカウントのみ（-sp を作らない配布者）: BLOCK6 の Instagram(@block6_boogie54) / 店 Boogie54(@boogie54yokohama) 配布用
DISC_ONLY_DJS=("BLOCK6|block6" "BOOGIE54|boogie54")

# _template_artist.html を discount 版から派生させる
sed \
 -e 's|DISCOUNT PASS{{TITLE_SUFFIX}}|GUEST PASS{{TITLE_SUFFIX}}|' \
 -e 's|<div class="subtitle">Discount Pass</div>|<div class="subtitle">Guest Pass</div>|' \
 -e 's|--ticket-a: #f7d21e;|--ticket-a: #47b6f0;|' \
 -e 's|--ticket-b: #e6b900;|--ticket-b: #2391d6;|' \
 -e 's|<div class="coupon-value">¥2,000</div>|<div class="coupon-value">¥1,000</div>|' \
 -e 's|aria-label="ディスカウントパス">|aria-label="関係者パス">|' \
 -e 's|<div class="coupon-tag"></div>|<div class="coupon-tag">音楽関係者専用</div>|' \
 -e 's@BLOCK6 | DISCOUNT PASS ¥2,500 → ¥2,000@BLOCK6 | GUEST PASS ¥2,500 → ¥1,000@' \
 _template_discount.html > _template_artist.html
echo "wrote  _template_artist.html"

# _template_free.html を discount 版から派生させる
sed \
 -e 's|DISCOUNT PASS{{TITLE_SUFFIX}}|FREE PASS{{TITLE_SUFFIX}}|' \
 -e 's|<div class="subtitle">Discount Pass</div>|<div class="subtitle">Free Pass</div>|' \
 -e 's|--ticket-a: #f7d21e;|--ticket-a: #ff6ab5;|' \
 -e 's|--ticket-b: #e6b900;|--ticket-b: #ef3f90;|' \
 -e 's|<div class="coupon-value">¥2,000</div>|<div class="coupon-value">FREE</div>|' \
 -e 's|aria-label="ディスカウントパス">|aria-label="フリーパス">|' \
 -e 's|<div class="coupon-tag"></div>|<div class="coupon-tag">フリーゲスト（音楽関係者のみ）</div>|' \
 -e 's@BLOCK6 | DISCOUNT PASS ¥2,500 → ¥2,000@BLOCK6 | FREE PASS（音楽関係者のみ）@' \
 _template_discount.html > _template_free.html
echo "wrote  _template_free.html"

# (dj, slug) を1行ずつ書く一時ファイル
disc_map=$(mktemp)
artist_map=$(mktemp)
free_map=$(mktemp)
trap 'rm -f "$disc_map" "$artist_map" "$free_map"' EXIT

# 人数注記。空文字なら .coupon-group:empty で非表示になる。
GROUP_NOTE_DISCOUNT=""
GROUP_NOTE_ARTIST="1枚で3名まで有効"
GROUP_NOTE_FREE="1枚で3名まで有効"

# リストバンド注記（チケット地色と同じ色のバンドを受付で渡す）。空文字なら .coupon-band:empty で非表示。
BAND_NOTE_DISCOUNT="受付でイエローのリストバンドをお渡しします"
BAND_NOTE_ARTIST="受付でブルーのリストバンドをお渡しします"
BAND_NOTE_FREE="受付でピンクのリストバンドをお渡しします"

# ルートページ(IG bio の飛び先): パス本体は載せない(09-15 keiju)。イベント案内+LINKS欄(_links.html: Mixcloud/IG/会場/パス案内→UEのパス /ue/ へのリンク)。
# カウントダウンは無し(09-13 keiju「カウントダウンいらない」)
sed \
 -e 's|<title>BLOCK6 — DISCOUNT PASS{{TITLE_SUFFIX}}</title>|<title>BLOCK6 — 9/26 (SAT) @ Boogie54 Yokohama</title>|' \
 -e 's|<div class="subtitle">Discount Pass</div>|<div class="subtitle">@ Boogie54 Yokohama</div>|' \
 -e 's#BLOCK6 | DISCOUNT PASS ¥2,500 → ¥2,000#BLOCK6 | 9/26 (SAT) @ Boogie54 Yokohama#' \
 -e '/<section class="coupon"/,/<\/section>/d' \
 -e '/rule-after-pass/d' \
 -e '/rule-after-clock/d' \
 -e '/<section class="clock"/,/<\/section>/d' \
 -e "s|{{GA4_ID}}|${GA4_ID}|g" \
 -e "s|{{BASE_URL}}|${BASE_URL}|g" \
 -e "s|{{OG_IMAGE}}|${BASE_URL}/ogp.jpg|g" \
 -e 's|{{LOGO_SRC}}|logo_glow.png|g' \
 -e 's|{{GROUP_NOTE}}||g' \
 -e 's|{{BAND_NOTE}}||g' \
 -e 's|{{NAME_CLASS}}||g' \
 -e '/{{LINKS}}/{' -e 'r _links.html' -e 'd' -e '}' \
 _template_discount.html > index.html
echo "wrote  index.html"


generate() {
  local dj="$1"
  local dir="$2"
  local template="$3"
  local map_file="$4"
  local group_note="$5"
  local band_note="$6"

  printf '%s\t%s\n' "$dj" "$dir" >> "$map_file"

  # 表示名が長い（6文字超）ときはチケット内で縮小するクラスを付ける
  local name_class=""
  if [ "${#dj}" -gt 6 ]; then name_class=" long"; fi

  mkdir -p "$dir"
  sed -e "s|{{DJ_NAME}}|${dj}|g" \
      -e "s|{{NAME_CLASS}}|${name_class}|g" \
      -e "s|{{TITLE_SUFFIX}}| (${dj})|g" \
      -e "s|{{GA4_ID}}|${GA4_ID}|g" \
      -e "s|{{BASE_URL}}|${BASE_URL}|g" \
      -e "s|{{OG_IMAGE}}|${BASE_URL}/og/${dir}.jpg|g" \
      -e 's|{{LOGO_SRC}}|../logo_glow.png|g' \
      -e "s|{{GROUP_NOTE}}|${group_note}|g" \
      -e "s|{{BAND_NOTE}}|${band_note}|g" \
      -e '/{{LINKS}}/d' \
      "$template" > "${dir}/index.html"
  echo "wrote  ${dir}/index.html"
}

for entry in "${DJS[@]}"; do
  dj="${entry%%|*}"
  slug="${entry##*|}"
  generate "$dj" "$slug" "_template_discount.html" "$disc_map" "$GROUP_NOTE_DISCOUNT" "$BAND_NOTE_DISCOUNT"
  generate "$dj" "${slug}-sp" "_template_artist.html" "$artist_map" "$GROUP_NOTE_ARTIST" "$BAND_NOTE_ARTIST"
done

for entry in "${DISC_ONLY_DJS[@]}"; do
  dj="${entry%%|*}"
  slug="${entry##*|}"
  generate "$dj" "$slug" "_template_discount.html" "$disc_map" "$GROUP_NOTE_DISCOUNT" "$BAND_NOTE_DISCOUNT"
done

for entry in "${FREE_DJS[@]}"; do
  dj="${entry%%|*}"
  slug="${entry##*|}"
  generate "$dj" "${slug}-free" "_template_free.html" "$free_map" "$GROUP_NOTE_FREE" "$BAND_NOTE_FREE"
done

{
  echo "# BLOCK6 — パスURL一覧"
  echo
  echo "9/26 (SAT) @ Boogie54 Yokohama。配布者別のパスURL。ルートはイベント案内+LINKS（パス本体なし・UEの2000円パスへのリンクあり）。"
  echo "チケットの地色は受付で渡すリストバンドの色と同じ（当日客=グリーンはバンドのみ）。"
  echo
  echo "## URL一覧"
  echo
  echo "**ルート（イベント案内+LINKS・IG bio の飛び先・UEパスへのリンク）:** ${BASE_URL}/"
  echo
  echo "**2000円ゲスト（イエロー・¥2,500 → ¥2,000）:**"
  echo
  echo "| 配布者 | URL |"
  echo "|----|-----|"
  while IFS=$'\t' read -r dj dir; do
    echo "| ${dj} | ${BASE_URL}/${dir}/ |"
  done < "$disc_map"
  echo
  echo "**関係者（ブルー・¥2,500 → ¥1,000・1枚で5名まで）:**"
  echo
  echo "| 配布者 | URL |"
  echo "|----|-----|"
  while IFS=$'\t' read -r dj dir; do
    echo "| ${dj} | ${BASE_URL}/${dir}/ |"
  done < "$artist_map"
  echo
  echo "**フリー（ピンク・FREE・音楽関係者のみ・1枚で3名まで）:**"
  echo
  echo "| 配布者 | URL |"
  echo "|----|-----|"
  while IFS=$'\t' read -r dj dir; do
    echo "| ${dj} | ${BASE_URL}/${dir}/ |"
  done < "$free_map"
  echo
  echo "## ビルド"
  echo
  echo '```bash'
  echo "./build.sh"
  echo '```'
  echo
  echo "独自ドメイン: block6.djue.me（GoDaddy DNS で CNAME block6 → puenots.github.io）。"
  echo "GA4 測定IDは build.sh 冒頭の GA4_ID。"
} > README.md

echo "wrote  README.md"
