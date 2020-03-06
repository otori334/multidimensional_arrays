#!/bin/bash 

ORI_IFS=${IFS} 

# 状態変数を定義する関数 
function def_state() { 
  # 引数は二つでもいい 
  local _PRE_IFS=${IFS} 
    eval $1="${2:-$(eval echo "$1")}" 
    # ARRAY_STATE_NAMEは状態変数の名前を格納する配列 
    ARRAY_STATE_NAME+=( $1 ) 
    # ARRAY_STATE_NUMBERはこれまでに定義された状態変数の数を格納する変数 
    ARRAY_STATE_NUMBER=${#ARRAY_STATE_NAME[@]} 
    if [ ${ARRAY_STATE_NUMBER} -eq 1 ]; then 
      # 状態変数を記録する配列 
      array_state=() 
    fi 
    # ARRAY_STATE_MINIMALは状態変数の規定値を格納する配列 
    # min_stateで参照する 
    ARRAY_STATE_MINIMAL+=( "${2:-$(eval echo "$1")}" ) 
    # ARRAY_STATE_INFLUENCEは状態変数の影響力を格納する配列 
    # infl_stateで参照する 
    ARRAY_STATE_INFLUENCE+=( $(( 10 - ${#ARRAY_STATE_NAME[@]} )) ) 
    # ARRAY_STATE_NUMBER_$1は状態変数のindexを格納する変数（連想配列みたいに使う）
    # rev_stateで使う 
    eval ARRAY_STATE_NUMBER_$1=$(( ${#ARRAY_STATE_NAME[@]} - 1 )) 
    # Thanks to https://qiita.com/mtomoaki_96Influencekg/items/ff82305f1ff4bb4c827c 
  IFS=_ 
    ARRAY_STATE_MINIMAL_HEAD="${ARRAY_STATE_MINIMAL[*]}" 
  IFS=${_PRE_IFS} 
  return 0 
} 

# 状態変数一覧のindexを逆引きする関数 
# reverse_state 
function rev_state() { 
  eval echo '$'ARRAY_STATE_NUMBER_$1 
  return 0 
} 

# 状態変数の規定値を調べる関数 
# minimal_state 
function min_state() { 
  echo "${ARRAY_STATE_MINIMAL[$(eval echo '$'ARRAY_STATE_NUMBER_$1)]}" 
  return 0 
} 

# 状態変数を規定値に戻す関数 
# テストしてないし $(buffer="buffer"; read_state) の方が簡潔なので非推奨
function rev_min_state() { 
  eval $1="${ARRAY_STATE_MINIMAL[$(eval echo '$'ARRAY_STATE_NUMBER_$1)]}" 
} 

# 状態変数の影響力を調べる関数 
# influence_state 
function infl_state() { 
  echo "${ARRAY_STATE_INFLUENCE[$(eval echo '$'ARRAY_STATE_NUMBER_$1)]}" 
  return 0 
} 

# グローバル変数である状態変数にスコープを与える関数 
function check_state() { 
  # 各状態変数をarray_stateに記録する 
  local _PRE_IFS=${IFS} 
    local _maximal_check=() 
    local _state_check=0 
    for _state_check in "${ARRAY_STATE_NAME[@]}"; do 
      eval _maximal_check+=( $(eval echo '"${'${_state_check}'}"') ) 
    done 
  IFS=_ 
    ARRAY_STATE_MAXIMAL_HEAD="${_maximal_check[*]}" 
    array_state+=( "${ARRAY_STATE_MAXIMAL_HEAD}" ) 
  IFS=${_PRE_IFS} 
  return 0 
} 

# グローバル変数である状態変数にスコープを与える関数，check_stateと合わせて使う 
function rest_state() { 
  # 各状態変数をarray_stateの内容に戻す関数 
  # Thanks to https://qiita.com/tommarute/items/0085e33ac9271fbd74e1 
  # アンダーバー区切りの末尾要素から要素を抽出 
  local _PRE_IFS=${IFS}; IFS=${ORI_IFS} 
    local _part_rest=( $( echo "${array_state[$(( ${#array_state[@]} - 1 ))]}" | tr -s '_' ' ') ) 
    # Thanks to https://qiita.com/b4b4r07/items/e56a8e3471fb45df2f59 
    # 配列の末尾要素を読んで状態変数を復元（破壊的操作）
    array_state=( "${array_state[@]:0:$(( ${#array_state[@]} - 1 ))}" ) 
    local _index_rest=0 
    local _state_rest=0 
    for _state_rest in "${_part_rest[@]}"; do 
      eval $(echo "${ARRAY_STATE_NAME[${_index_rest}]}")="${_state_rest}" 
      _index_rest=$(( _index_rest + 1 )) 
    done 
  IFS=${_PRE_IFS} 
  return 0 
} 

# 記録された状態変数を読む関数 
# check_stateをさかのぼって状態変数を読むことができる 
function read_state() { 
  if [ $# -eq 0 ] || [ $1 -eq 0 ]; then 
    check_state 
      echo "${ARRAY_STATE_MAXIMAL_HEAD}" 
    rest_state 
    return 
  else 
    echo "${array_state[$(( ${#array_state[@]} - $1 ))]}" 
  fi 
  return 0 
} 

# 引数で指定された配列名を生成する関数 
# 状態変数の序列を変えるとバグるため非推奨 
function spec_state() { 
  if [ $# -eq $ARRAY_STATE_NUMBER ]; then 
    local _PRE_IFS=${IFS} 
      local _maximal_spec=( "$@" ) 
    IFS=_ 
      echo "${_maximal_spec[*]}" 
    IFS=${_PRE_IFS} 
    return 
  else 
    : # エラーハンドリング 
    return 1 
  fi 
  return 0 
} 

# 引数で指定した部分を書き換える関数 
# 第一引数は配列名，第二引数以降は書き換えたい状態変数と書き換える内容を交互にいれる 
# "roster $(xor_buffer; read_state) '*'" のようにした方が簡潔 
function edit_state() { 
  if [ $# -ge 3 ]; then 
    local _PRE_IFS=${IFS}; IFS=${ORI_IFS} 
      local _part_edit=( $( echo "$1" | tr -s '_' ' ') ) 
      if [ ${#_part_edit[@]} -ne $ARRAY_STATE_NUMBER ]; then 
        : # エラーハンドリング 
        exit 1 
      fi 
      shift 1 
      until [ "$1" = "" ]; do 
        _part_edit[$(rev_state $1)]="$2" 
        shift 2 
      done 
    IFS=_ 
      echo "${_part_edit[*]}" 
    IFS=${_PRE_IFS} 
  else 
    : # エラーハンドリング 
    exit 1 
  fi 
  return 0 
} 

# 定義されるよりも前に遡る場合はデフォルト値に書き換わるようにしたい 
# 状態変数の影響力を比べる機能を組み込みたい 
# まだ 

# 擬多次元配列を参照する関数 
# Thanks to https://aki-yam.hatenablog.com/entry/20081105/1225865004 
function roster() { 
  if [ $# -eq 0 ]; then 
    eval echo '"${'$(read_state)'[@]}"' 
    return 0 
  fi 
  if [ $# -eq 1 ]; then 
    eval echo '"${'$(read_state)'['$1']}"' 
    return 0 
  fi 
  if [ $# -eq 2 ]; then 
    eval echo '"${'$1'['$2']}"' 
    return 0 
  fi 
  : # エラーハンドリング 
  exit 1 
} 
