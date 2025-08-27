#!/bin/sh

# download-workshop.sh
# Desc: Descarga ítems de Steam Workshop de KF2 con steamcmd (login anónimo)
#       leyendo los IDs desde la variable de entorno KF2_WORKSHOP y
#       sincroniza el contenido a serverfiles/KFGame/Cache.
#
# Requisitos:
# - steamcmd disponible en PATH o define STEAMCMD="/ruta/a/steamcmd"
# - Variable KF2_WORKSHOP con una lista tipo JSON: [123,456,...]
#
# Opciones:
#   --list       Muestra los IDs detectados y sale
#   --dry-run    No ejecuta descargas ni copias, solo muestra acciones
#   --no-download  Omite la fase de steamcmd (solo indexa/copias/config)
#   --retries N  Reintentos por ítem (defecto: 2)
#   --appid ID   AppID de Workshop (defecto: 232090 para KF2)
#   --use-web-api  Usa Steam Web API para comprobar cambios sin descargar (requiere curl)
#   --api-timeout S Timeout en segundos para la Web API (defecto: 10)
#

set -eu

APPID=232090
RETRIES=2
DRY_RUN=0
MODE_LIST=0
# Saltar descarga completa
NO_DOWNLOAD=${NO_DOWNLOAD:-0}
# Web API
USE_WEB_API=${USE_WEB_API:-0}
API_TIMEOUT=${API_TIMEOUT:-10}
STEAM_API_URL=${STEAM_API_URL:-"https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/"}
# Nivel extra silencioso para reducir casi toda la salida del script (predeterminado OFF)
VERY_QUIET=${VERY_QUIET:-0}
# Si se pone a 1, ejecuta steamcmd con HOME=$WORKDIR para forzar que
# todo el contenido (incluido workshop) se almacene bajo $WORKDIR.
FORCE_STEAM_HOME_IN_WORKDIR=${FORCE_STEAM_HOME_IN_WORKDIR:-0}

# Modo silencioso y archivo de log (afecta a steamcmd). Por defecto ON para silenciar steamcmd.
QUIET=${QUIET:-1}
LOG_FILE=${LOG_FILE:-/data/log/steam/steamcmd-download.log}

# Rutas
WORKDIR=${STEAMCMD_HOME:-/data/steamcmd}
SERVER_ROOT=${SERVER_ROOT:-/data/serverfiles}
DEST_CACHE=${DEST_CACHE:-"$SERVER_ROOT/KFGame/Cache"}
INDEX_JSON=${INDEX_JSON:-/data/workshop-index.json}
LINUX_KFGAME_INI=${LINUX_KFGAME_INI:-"$SERVER_ROOT/KFGame/Config/kf2server/LinuxServer-KFGame.ini"}

# Binario steamcmd
STEAMCMD_BIN=${STEAMCMD:-steamcmd}

usage() {
  echo "Uso: $0 [--list] [--dry-run] [--no-download] [--quiet] [--no-quiet] [--very-quiet] [--no-very-quiet] [--retries N] [--appid APPID] [--use-web-api] [--api-timeout S] [--log-file RUTA]" >&2
}

# Parse args simples
while [ $# -gt 0 ]; do
  case "$1" in
    --list) MODE_LIST=1 ;;
  --dry-run) DRY_RUN=1 ;;
  --no-download) NO_DOWNLOAD=1 ;;
  --quiet) QUIET=1 ;;
    --no-quiet) QUIET=0 ;;
    --very-quiet) VERY_QUIET=1; QUIET=1 ;;
    --no-very-quiet) VERY_QUIET=0 ;;
    --retries) shift; [ $# -gt 0 ] || { usage; exit 1; }; RETRIES=$1 ;;
    --appid) shift; [ $# -gt 0 ] || { usage; exit 1; }; APPID=$1 ;;
  --use-web-api) USE_WEB_API=1 ;;
  --api-timeout) shift; [ $# -gt 0 ] || { usage; exit 1; }; API_TIMEOUT=$1 ;;
  --log-file) shift; [ $# -gt 0 ] || { usage; exit 1; }; LOG_FILE=$1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opción no reconocida: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

# Enlazar very-quiet con quiet aunque provenga de variable por defecto
if [ "$VERY_QUIET" -eq 1 ]; then
  QUIET=1
fi

# Obtiene IDs desde KF2_WORKSHOP (formato esperado: [id1,id2,...])
RAW=${KF2_WORKSHOP:-}
if [ -z "$RAW" ]; then
  echo "Error: KF2_WORKSHOP no está definido." >&2
  echo "Ejemplo: export KF2_WORKSHOP='[2592435250,3480853434]'" >&2
  exit 1
fi

# Normaliza: quita [ ], espacios y comillas, separa por nueva línea y deduplica
IDS=$(printf "%s" "$RAW" \
  | tr -d '[]' \
  | tr -d '"' \
  | tr ',' '\n' \
  | sed 's/^ *//; s/ *$//' \
  | grep -E '^[0-9]+$' \
  | sort -u)

if [ -z "$IDS" ]; then
  echo "No se detectaron IDs válidos en KF2_WORKSHOP: $RAW" >&2
  exit 1
fi

if [ "$MODE_LIST" -eq 1 ]; then
  echo "IDs detectados (deduplicados):"
  echo "$IDS"
  exit 0
fi

# Verificaciones de entorno
if [ "$DRY_RUN" -ne 1 ]; then
  if ! command -v "$STEAMCMD_BIN" >/dev/null 2>&1; then
    echo "Error: no se encontró steamcmd (STEAMCMD_BIN=$STEAMCMD_BIN)." >&2
    echo "Define STEAMCMD=\"/ruta/a/steamcmd\" o agrega steamcmd al PATH." >&2
    exit 1
  fi
fi

mkdir -p "$WORKDIR" "$DEST_CACHE"
mkdir -p "$(dirname "$LOG_FILE")"

WORKSHOP_ROOT="$WORKDIR/steamapps/workshop/content/$APPID"
# Ruta alternativa donde SteamCMD suele depositar Workshop por defecto
HOME_WORKSHOP_ROOT="${STEAM_USER_HOME:-$HOME}/.local/share/Steam/steamapps/workshop/content/$APPID"

[ "$VERY_QUIET" -ne 1 ] && echo "Trabajo en: $WORKDIR"
[ "$VERY_QUIET" -ne 1 ] && echo "Cache destino: $DEST_CACHE"
[ "$VERY_QUIET" -ne 1 ] && echo "Workshop raíz (post-descarga): $WORKSHOP_ROOT"
[ "$VERY_QUIET" -ne 1 ] && echo "AppID Workshop: $APPID"
[ "$VERY_QUIET" -ne 1 ] && echo "Reintentos por ítem: $RETRIES"
[ "$VERY_QUIET" -ne 1 ] && echo "Modo dry-run: $DRY_RUN"
[ "$VERY_QUIET" -ne 1 ] && echo "Quiet: $QUIET (log: $LOG_FILE), VeryQuiet: $VERY_QUIET"

# Local metadata (ACF) path candidates
APPWORKSHOP_ACF_HOME="${STEAM_USER_HOME:-$HOME}/.local/share/Steam/steamapps/workshop/appworkshop_${APPID}.acf"
APPWORKSHOP_ACF_WORKDIR="$WORKDIR/steamapps/workshop/appworkshop_${APPID}.acf"

# Leer bloque ACF por ID: devuelve líneas del bloque
acf_block_for_id() {
  _acf="$1"; _id="$2"
  [ -f "$_acf" ] || return 1
  # Buscamos bajo WorkshopItemsInstalled
  awk -v id="\"${_id}\"" '
    $0 ~ /\"WorkshopItemsInstalled\"/ {inSection=1; next}
    inSection && $0 ~ id {depth=1; print; next}
    inSection && depth>0 {
      print
      if ($0 ~ /\{/) depth++
      if ($0 ~ /\}/) {depth--; if(depth==0) exit}
    }
  ' "$_acf"
}

# Extraer campo simple "key" "value" del bloque
acf_field_value() {
  _block="$1"; _key="$2"
  # Escapar metacaracteres de sed/regex en la clave
  _ekey=$(printf '%s' "$_key" | sed 's/[.[\*^$+?{}|()\\]/\\&/g')
  # Usar comillas simples en el script sed para no romper el [^"]
  printf '%s\n' "$_block" | sed -n 's/^[[:space:]]*"'"$_ekey"'"[[:space:]]*"\([^\"]*\)".*/\1/p' | head -n1
}

# Obtener manifest/timeupdated locales para un ID
get_local_manifest_and_timeupdated() {
  _id="$1"
  for acf in "$APPWORKSHOP_ACF_HOME" "$APPWORKSHOP_ACF_WORKDIR"; do
    blk=$(acf_block_for_id "$acf" "$_id" 2>/dev/null || true)
    if [ -n "$blk" ]; then
      man=$(acf_field_value "$blk" manifest || true)
      tup=$(acf_field_value "$blk" timeupdated || true)
      echo "$man|$tup"
      return 0
    fi
  done
  echo "|"; return 1
}

# Consultar Web API para lote de IDs: imprime "id|time_updated" por línea
webapi_get_time_updated_batch() {
  ids="$1"
  command -v curl >/dev/null 2>&1 || { return 1; }
  # Construir payload application/x-www-form-urlencoded
  payload="itemcount=$(printf "%s" "$ids" | wc -l | tr -d ' ')"
  idx=0
  while read -r id; do
    payload="$payload&publishedfileids[$idx]=$id"
    idx=$((idx+1))
  done <<EOF
$ids
EOF
  resp=$(curl -sS --max-time "$API_TIMEOUT" -X POST -d "$payload" "$STEAM_API_URL" || true)
  [ -n "$resp" ] || return 1
  # Parse sencillo: buscar pares id/time_updated
  # Nota: resp es JSON; usamos sed/grep básico para evitar dependencias
  printf "%s\n" "$resp" | tr '\n' ' ' \
    | sed 's/}/}\n/g' \
    | grep -E '"publishedfileid"|"time_updated"' \
    | awk 'BEGIN{id=""} /publishedfileid/ {gsub(/[^0-9]/,""); id=$0} /time_updated/ {gsub(/[^0-9]/,""); if(id!=""){print id"|"$0; id=""}}'
}

# Helpers para leer valores previos del índice (usados en el bucle de descargas)
get_old_manifest() {
  _id="$1"
  [ -f "$INDEX_JSON" ] || { return 1; }
  sed -n "/\"${_id}\"[[:space:]]*:/,/}/p" "$INDEX_JSON" \
    | sed -n 's/.*"manifestLocal"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n1
}

get_old_timeupdated_local() {
  _id="$1"
  [ -f "$INDEX_JSON" ] || { return 1; }
  sed -n "/\"${_id}\"[[:space:]]*:/,/}/p" "$INDEX_JSON" \
    | sed -n 's/.*"timeUpdatedLocal"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n1
}

get_old_timeupdated_api() {
  _id="$1"
  [ -f "$INDEX_JSON" ] || { return 1; }
  sed -n "/\"${_id}\"[[:space:]]*:/,/}/p" "$INDEX_JSON" \
    | sed -n 's/.*"timeUpdatedApi"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n1
}

# Descarga y sincroniza por ítem
SUCCESS=0
FAIL=0

# Mapa de time_updated API (si se usa)
API_TIMES_TEMP="/tmp/kf2_api_times_$$.txt"
if [ "$USE_WEB_API" -eq 1 ]; then
  if out=$(webapi_get_time_updated_batch "$IDS" 2>/dev/null); then
    printf "%s\n" "$out" > "$API_TIMES_TEMP"
    [ "$VERY_QUIET" -ne 1 ] && echo "Web API: metadata obtenida para $(wc -l < "$API_TIMES_TEMP" | tr -d ' ') items"
  else
    [ "$VERY_QUIET" -ne 1 ] && echo "Web API: no disponible, continuo sin API"
    USE_WEB_API=0
  fi
fi

for ID in $IDS; do
  [ "$VERY_QUIET" -ne 1 ] && echo "---"
  [ "$VERY_QUIET" -ne 1 ] && echo "Procesando ítem $ID"

  ATTEMPT=0
  DOWN_OK=0
  # Decidir si omitir descarga
  SKIP_DL=0
  # 1) Metadatos locales (manifest)
  lmeta=$(get_local_manifest_and_timeupdated "$ID" || true)
  lman=${lmeta%%|*}
  ltup=${lmeta#*|}
  # 2) Estado previo (JSON)
  pman=$(get_old_manifest "$ID" || true)
  ptla=$(get_old_timeupdated_local "$ID" || true)
  ptapi=$(get_old_timeupdated_api "$ID" || true)
  # 3) Web API time_updated
  atup=""
  if [ "$USE_WEB_API" -eq 1 ] && [ -f "$API_TIMES_TEMP" ]; then
    atup=$(grep -E "^${ID}[|]" "$API_TIMES_TEMP" | head -n1 | cut -d '|' -f2)
  fi

  # Regla: si NO_DOWNLOAD=1 -> saltar; si API habilitada y atup == ltup (y existe), saltar; si hay manifest local y directorio presente, podemos saltar
  if [ "$NO_DOWNLOAD" -eq 1 ]; then
    SKIP_DL=1
  elif [ -n "$atup" ] && [ -n "$ltup" ] && [ "$atup" = "$ltup" ]; then
    SKIP_DL=1
    [ "$VERY_QUIET" -ne 1 ] && echo "Saltando descarga (API sin cambios): $ID"
  elif [ -n "$lman" ] && [ -n "$pman" ] && [ "$lman" = "$pman" ] && { [ -d "$WORKSHOP_ROOT/$ID" ] || [ -d "$HOME_WORKSHOP_ROOT/$ID" ]; }; then
    SKIP_DL=1
    [ "$VERY_QUIET" -ne 1 ] && echo "Saltando descarga (manifest local presente): $ID"
  fi

  if [ "$SKIP_DL" -eq 1 ]; then
    DOWN_OK=1
  fi
  while [ $ATTEMPT -le $RETRIES ] && [ $DOWN_OK -ne 1 ]; do
    if [ "$DRY_RUN" -eq 1 ]; then
      [ "$VERY_QUIET" -ne 1 ] && echo "[dry-run] Descargar: steamcmd +login anonymous +workshop_download_item $APPID $ID +quit"
      DOWN_OK=1
      break
    else
      [ "$VERY_QUIET" -ne 1 ] && echo "Descargando (intento $((ATTEMPT+1))/$((RETRIES+1)))…"
      # Ejecuta steamcmd desde el WORKDIR para que el contenido quede ahí
      if [ "$FORCE_STEAM_HOME_IN_WORKDIR" -eq 1 ]; then
        if [ "$QUIET" -eq 1 ]; then
          (
            cd "$WORKDIR" && HOME="$WORKDIR" "$STEAMCMD_BIN" \
              +@NoPromptForPassword 1 \
              +@ShutdownOnFailedCommand 1 \
              +login anonymous \
              +workshop_download_item "$APPID" "$ID" validate \
              +quit
          ) >>"$LOG_FILE" 2>&1
          rc=$?
          if [ $rc -eq 0 ]; then DOWN_OK=1; break; fi
        else
      if ( cd "$WORKDIR" && HOME="$WORKDIR" "$STEAMCMD_BIN" +@NoPromptForPassword 1 +@ShutdownOnFailedCommand 1 +login anonymous +workshop_download_item "$APPID" "$ID" validate +quit ); then
            DOWN_OK=1
            break
          fi
        fi
      else
        if [ "$QUIET" -eq 1 ]; then
          (
            cd "$WORKDIR" && "$STEAMCMD_BIN" \
        +@NoPromptForPassword 1 \
              +@ShutdownOnFailedCommand 1 \
              +login anonymous \
              +workshop_download_item "$APPID" "$ID" validate \
              +quit
          ) >>"$LOG_FILE" 2>&1
          rc=$?
          if [ $rc -eq 0 ]; then DOWN_OK=1; break; fi
        else
          if ( cd "$WORKDIR" && "$STEAMCMD_BIN" +@NoPromptForPassword 1 +@ShutdownOnFailedCommand 1 +login anonymous +workshop_download_item "$APPID" "$ID" validate +quit ); then
            DOWN_OK=1
            break
          fi
        fi
      fi
      ATTEMPT=$((ATTEMPT+1))
      sleep 1
    fi
  done

  if [ $DOWN_OK -ne 1 ]; then
    if [ "$QUIET" -eq 1 ]; then
      [ "$VERY_QUIET" -ne 1 ] && echo "Fallo: $ID (ver $LOG_FILE)"
    else
      echo "Fallo al descargar ítem $ID" >&2
    fi
    FAIL=$((FAIL+1))
    continue
  fi
  [ "$QUIET" -eq 1 ] && [ "$VERY_QUIET" -ne 1 ] && echo "OK descarga: $ID"

  # Sincroniza al Cache del servidor
  SRC_DIR="$WORKSHOP_ROOT/$ID"
  DST_DIR="$DEST_CACHE/$ID"
  if [ ! -d "$SRC_DIR" ]; then
    # Intentar ruta HOME por defecto de Steam
    ALT_SRC_DIR="$HOME_WORKSHOP_ROOT/$ID"
    if [ -d "$ALT_SRC_DIR" ]; then
      [ "$VERY_QUIET" -ne 1 ] && echo "Info: usando ruta alternativa de Workshop: $ALT_SRC_DIR"
      SRC_DIR="$ALT_SRC_DIR"
    else
      [ "$VERY_QUIET" -ne 1 ] && echo "Advertencia: no existe $SRC_DIR ni $ALT_SRC_DIR tras la descarga (posible Access Denied o ítem vacío)." >&2
      FAIL=$((FAIL+1))
      continue
    fi
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    [ "$VERY_QUIET" -ne 1 ] && echo "[dry-run] Copiar: $SRC_DIR -> $DST_DIR"
  else
    mkdir -p "$DST_DIR"
    # Copia preservando atributos básicos
    # shellcheck disable=SC2119
    cp -a "$SRC_DIR"/. "$DST_DIR"/
  fi

  [ "$VERY_QUIET" -ne 1 ] && echo "OK: $ID"
  SUCCESS=$((SUCCESS+1))
done

echo "---"
[ "$VERY_QUIET" -ne 1 ] && echo "Resumen descargas: OK=$SUCCESS, Fallos=$FAIL, Total=$((SUCCESS+FAIL))"

# ------------------------------------------------------------
# Fase 2: Indexar, comparar hash, copiar al Cache y configurar mapas
# ------------------------------------------------------------

TMP_JSON="$INDEX_JSON.tmp"

# Helper: obtener hash anterior desde JSON existente
get_old_hash() {
  _id="$1"
  [ -f "$INDEX_JSON" ] || { return 1; }
  sed -n "/\"${_id}\"[[:space:]]*:/,/}/p" "$INDEX_JSON" \
    | sed -n 's/.*"hash"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n1
}

# Helper: obtener nombre anterior (archivo .kfm)
get_old_name() {
  _id="$1"
  [ -f "$INDEX_JSON" ] || { return 1; }
  sed -n "/\"${_id}\"[[:space:]]*:/,/}/p" "$INDEX_JSON" \
    | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n1
}

 

# Helper: listar IDs previos en JSON
list_old_ids() {
  [ -f "$INDEX_JSON" ] || return 1
  grep -E '^[[:space:]]*"[0-9]+"[[:space:]]*:' "$INDEX_JSON" 2>/dev/null \
    | sed -E 's/^[[:space:]]*"([0-9]+)".*/\1/' \
    | sort -u
}

# Helper: eliminar bloque de config del INI para un mapa
remove_map_config() {
  _map="$1"
  [ -f "$LINUX_KFGAME_INI" ] || return 0
  header="[${_map} KFMapSummary]"
  if ! grep -Fq "$header" "$LINUX_KFGAME_INI"; then
    return 0
  fi
  tmpfile="${LINUX_KFGAME_INI}.tmp$$"
  awk -v header="$header" '
    BEGIN{skip=0}
    $0==header {skip=1; next}
    skip && /^\[/ {skip=0}
    !skip {print}
  ' "$LINUX_KFGAME_INI" > "$tmpfile" && mv -f "$tmpfile" "$LINUX_KFGAME_INI"
}

# Sanitiza un INI: elimina bytes NUL y CR finales (Windows)
sanitize_ini() {
  _file="$1"
  [ -f "$_file" ] || return 0
  tmpfile="${_file}.san.$$"
  tr -d '\000' < "$_file" | sed 's/\r$//' > "$tmpfile" && mv -f "$tmpfile" "$_file"
}

# Convierte Workshop INI y añade solo un bloque mínimo seguro (UTF-8)
append_workshop_config() {
  _src_cfg="$1"   # Ruta KFWorkshopMapSummary.ini
  _dst_ini="$2"   # Ruta LinuxServer-KFGame.ini
  _map_name="$3"  # Nombre de mapa (sin .kfm)
  if [ -z "$_src_cfg" ] || [ ! -f "$_src_cfg" ]; then
    return 1
  fi
  tmpcfg="/tmp/wcfg_$$.ini"
  ok=0
  if command -v iconv >/dev/null 2>&1; then
    if iconv -f UTF-16 -t UTF-8 "$_src_cfg" > "$tmpcfg" 2>/dev/null; then ok=1; fi
    if [ $ok -ne 1 ] && iconv -f UTF-16LE -t UTF-8 "$_src_cfg" > "$tmpcfg" 2>/dev/null; then ok=1; fi
    if [ $ok -ne 1 ] && iconv -f UTF-16BE -t UTF-8 "$_src_cfg" > "$tmpcfg" 2>/dev/null; then ok=1; fi
  fi
  if [ $ok -ne 1 ]; then
    tr -d '\000' < "$_src_cfg" | sed 's/\r$//' > "$tmpcfg"
  fi
  # Extraer campos relevantes (si existen)
  SCRSHOT=$(grep -E '^\s*ScreenshotPathName=' "$tmpcfg" | tail -n1 | sed 's/^\s*ScreenshotPathName=//') || SCRSHOT=
  MAPASSOC=$(grep -E '^\s*MapAssociation=' "$tmpcfg" | tail -n1 | sed 's/^\s*MapAssociation=//') || MAPASSOC=
  PLAY_SURV=$(grep -E '^\s*bPlayableInSurvival=' "$tmpcfg" | tail -n1 | sed 's/^\s*bPlayableInSurvival=//') || PLAY_SURV=
  PLAY_WEEK=$(grep -E '^\s*bPlayableInWeekly=' "$tmpcfg" | tail -n1 | sed 's/^\s*bPlayableInWeekly=//') || PLAY_WEEK=
  PLAY_VS=$(grep -E '^\s*bPlayableInVsSurvival=' "$tmpcfg" | tail -n1 | sed 's/^\s*bPlayableInVsSurvival=//') || PLAY_VS=
  PLAY_END=$(grep -E '^\s*bPlayableInEndless=' "$tmpcfg" | tail -n1 | sed 's/^\s*bPlayableInEndless=//') || PLAY_END=
  PLAY_OBJ=$(grep -E '^\s*bPlayableInObjective=' "$tmpcfg" | tail -n1 | sed 's/^\s*bPlayableInObjective=//') || PLAY_OBJ=

  # Construir bloque mínimo
  {
    printf "\n# managed-by: download-workshop.sh\n"
    printf "[%s KFMapSummary]\n" "$_map_name"
    printf "MapName=%s\n" "$_map_name"
    if [ -n "$SCRSHOT" ]; then
      printf "ScreenshotPathName=%s\n" "$SCRSHOT"
    else
      printf "ScreenshotPathName=UI_MapPreview_TEX.UI_MapPreview_Placeholder\n"
    fi
    [ -n "$MAPASSOC" ] && printf "MapAssociation=%s\n" "$MAPASSOC"
    [ -n "$PLAY_SURV" ] && printf "bPlayableInSurvival=%s\n" "$PLAY_SURV"
    [ -n "$PLAY_WEEK" ] && printf "bPlayableInWeekly=%s\n" "$PLAY_WEEK"
    [ -n "$PLAY_VS" ] && printf "bPlayableInVsSurvival=%s\n" "$PLAY_VS"
    [ -n "$PLAY_END" ] && printf "bPlayableInEndless=%s\n" "$PLAY_END"
    [ -n "$PLAY_OBJ" ] && printf "bPlayableInObjective=%s\n" "$PLAY_OBJ"
  } >> "$_dst_ini"

  rm -f "$tmpcfg"
}

# Helper: calcula hash (sha1 10 chars) del archivo
calc_hash() {
  _file="$1"
  if command -v sha1sum >/dev/null 2>&1; then
    sha1sum "$_file" | awk '{print $1}' | cut -c1-10
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 1 "$_file" | awk '{print $1}' | cut -c1-10
  elif command -v md5sum >/dev/null 2>&1; then
    md5sum "$_file" | awk '{print $1}' | cut -c1-10
  else
    echo "ERROR_NO_HASH_TOOL"
  fi
}

# Construir nueva base JSON con _meta
echo "{" > "$TMP_JSON"
printf "  \"_meta\": {\n" >> "$TMP_JSON"
printf "    \"generatedAt\": \"%s\",\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$TMP_JSON"
printf "    \"managed\": true,\n" >> "$TMP_JSON"
printf "    \"workshopAppId\": %s,\n" "$APPID" >> "$TMP_JSON"
printf "    \"workshopRoot\": \"%s\",\n" "$WORKSHOP_ROOT" >> "$TMP_JSON"
printf "    \"homeWorkshopRoot\": \"%s\",\n" "$HOME_WORKSHOP_ROOT" >> "$TMP_JSON"
printf "    \"cacheDir\": \"%s\",\n" "$DEST_CACHE" >> "$TMP_JSON"
printf "    \"workshopIds\": [" >> "$TMP_JSON"
first_id=1
for idv in $IDS; do
  [ $first_id -eq 1 ] && first_id=0 || printf "," >> "$TMP_JSON"
  printf "\"%s\"" "$idv" >> "$TMP_JSON"
done
printf "]\n" >> "$TMP_JSON"
printf "  },\n" >> "$TMP_JSON"

FIRST=1

COPIED=0
SKIPPED=0
MISSING=0
CFG_ADDED=0

for ID in $IDS; do
  # Detectar dir de origen para este ID
  SRC_DIR=""
  # Preferir la ruta HOME (lo que pidió el usuario) y luego fallback
  if [ -d "$HOME_WORKSHOP_ROOT/$ID" ]; then
    SRC_DIR="$HOME_WORKSHOP_ROOT/$ID"
  elif [ -d "$WORKSHOP_ROOT/$ID" ]; then
    SRC_DIR="$WORKSHOP_ROOT/$ID"
  fi

  if [ -z "$SRC_DIR" ]; then
  [ "$VERY_QUIET" -ne 1 ] && echo "Nota: no se encontró contenido para ID=$ID en $WORKSHOP_ROOT ni $HOME_WORKSHOP_ROOT"
    MISSING=$((MISSING+1))
    continue
  fi

  # Buscar primer .kfm
  KFM_PATH=$(find "$SRC_DIR" -type f -name '*.kfm' | head -n1 || true)
  if [ -z "$KFM_PATH" ]; then
  [ "$VERY_QUIET" -ne 1 ] && echo "Aviso: no se encontró archivo .kfm en $SRC_DIR (ID=$ID)." >&2
    MISSING=$((MISSING+1))
    continue
  fi

  KFM_NAME=$(basename "$KFM_PATH")
  MAP_NAME=${KFM_NAME%*.kfm}
  NEW_HASH=$(calc_hash "$KFM_PATH")
  OLD_HASH=$(get_old_hash "$ID" || true)

  # Detectar config
  FOUND_CFG=$(find "$SRC_DIR" -type f -name 'KFWorkshopMapSummary.ini' -print -quit || true)
  CFG_BOOL=false
  [ -n "$FOUND_CFG" ] && CFG_BOOL=true

  # Decidir copia
  NEED_COPY=0
  if [ -z "$OLD_HASH" ]; then
    NEED_COPY=1
  elif [ "$OLD_HASH" != "$NEW_HASH" ]; then
    NEED_COPY=1
  elif [ ! -d "$DEST_CACHE/$ID" ]; then
    NEED_COPY=1
  fi

  if [ "$NEED_COPY" -eq 1 ]; then
    [ "$VERY_QUIET" -ne 1 ] && echo "Copiando ID=$ID -> $DEST_CACHE/$ID (hash: $OLD_HASH -> $NEW_HASH)"
    if [ "$DRY_RUN" -ne 1 ]; then
      rm -rf "$DEST_CACHE/$ID"
      mkdir -p "$DEST_CACHE/$ID"
      cp -a "$SRC_DIR"/. "$DEST_CACHE/$ID"/
    else
      [ "$VERY_QUIET" -ne 1 ] && echo "[dry-run] rm -rf \"$DEST_CACHE/$ID\" && cp -a \"$SRC_DIR\"/. \"$DEST_CACHE/$ID\"/"
    fi
    COPIED=$((COPIED+1))
  else
    SKIPPED=$((SKIPPED+1))
  fi

  # Insertar configuración de mapa si falta en LinuxServer-KFGame.ini
  MAP_HEADER="[${MAP_NAME} KFMapSummary]"
  # Considerar que ya existe si hay una línea MapName=MAP_NAME
  if [ -f "$LINUX_KFGAME_INI" ] && grep -Fq "MapName=${MAP_NAME}" "$LINUX_KFGAME_INI"; then
    : # ya existe
  else
    [ "$VERY_QUIET" -ne 1 ] && echo "Agregando config de mapa para $MAP_NAME en $LINUX_KFGAME_INI"
    if [ "$DRY_RUN" -ne 1 ]; then
      # Crear archivo si no existe
      mkdir -p "$(dirname "$LINUX_KFGAME_INI")"
      touch "$LINUX_KFGAME_INI"
      # Sanitizar el INI destino antes de añadir
      sanitize_ini "$LINUX_KFGAME_INI" || true
      if [ -n "$FOUND_CFG" ]; then
        append_workshop_config "$FOUND_CFG" "$LINUX_KFGAME_INI" "$MAP_NAME"
      else
        {
          printf "\n# managed-by: download-workshop.sh\n"
          printf "%s\n" "$MAP_HEADER"
          printf "MapName=%s\n" "$MAP_NAME"
          printf "ScreenshotPathName=UI_MapPreview_TEX.UI_MapPreview_Placeholder\n"
        } >> "$LINUX_KFGAME_INI"
      fi
    else
      [ "$VERY_QUIET" -ne 1 ] && echo "[dry-run] Append config para $MAP_NAME (header $MAP_HEADER)"
    fi
    CFG_ADDED=$((CFG_ADDED+1))
  fi

  # Añadir entrada JSON
  [ $FIRST -eq 1 ] && FIRST=0 || echo "," >> "$TMP_JSON"
  {
    printf "  \"%s\": {\n" "$ID"
    printf "    \"dir\": \"%s\",\n" "$ID"
    printf "    \"name\": \"%s\",\n" "$KFM_NAME"
    printf "    \"hash\": \"%s\",\n" "$NEW_HASH"
  printf "    \"config\": %s,\n" "$CFG_BOOL"
  printf "    \"manifestLocal\": \"%s\",\n" "${lman:-}"
  printf "    \"timeUpdatedLocal\": \"%s\",\n" "${ltup:-}"
  printf "    \"timeUpdatedApi\": \"%s\"\n" "${atup:-}"
    printf "  }\n"
  } >> "$TMP_JSON"
done

echo "}" >> "$TMP_JSON"

if [ "$DRY_RUN" -ne 1 ]; then
  mv -f "$TMP_JSON" "$INDEX_JSON"
else
  echo "[dry-run] Actualizaría JSON en: $INDEX_JSON"
fi

echo "---"
echo "Resumen copias: Copiados=$COPIED, Omitidos=$SKIPPED, Faltantes=$MISSING, Configs añadidas=$CFG_ADDED"

# ------------------------------------------------------------
# Fase 3: Prune de mapas que ya no están en KF2_WORKSHOP
# ------------------------------------------------------------

PRUNED=0
if [ -f "$INDEX_JSON" ]; then
  NEW_IDS_FILE="/tmp/new_ids_$$.txt"
  echo "$IDS" > "$NEW_IDS_FILE"
  for OLD in $(list_old_ids || true); do
    if ! grep -qx "$OLD" "$NEW_IDS_FILE"; then
      # Eliminar del Cache
      if [ -d "$DEST_CACHE/$OLD" ]; then
        if [ "$DRY_RUN" -ne 1 ]; then
          rm -rf "$DEST_CACHE/$OLD"
        else
          echo "[dry-run] rm -rf \"$DEST_CACHE/$OLD\""
        fi
      fi
      # Eliminar config del INI
      OLD_NAME=$(get_old_name "$OLD" || true)
      if [ -n "$OLD_NAME" ]; then
        OLD_MAP=${OLD_NAME%*.kfm}
        if [ "$DRY_RUN" -ne 1 ]; then
          remove_map_config "$OLD_MAP"
        else
          echo "[dry-run] remove config block for $OLD_MAP"
        fi
      fi
      PRUNED=$((PRUNED+1))
    fi
  done
  rm -f "$NEW_IDS_FILE"
fi

echo "Prune: Eliminados=$PRUNED"

# Cleanup temporales
[ -f "$API_TIMES_TEMP" ] && rm -f "$API_TIMES_TEMP" || true

exit 0
