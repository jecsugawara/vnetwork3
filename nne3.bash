# E03
#  2台のルーターで3つのネットワークを接続する
#  4つのネームスペースns1,router1,router2,ns2を作成し、それぞれに仮想イーサネット
#  インタフェースを追加しIPアドレスを設定する。ネットワークセグメントは3つあり、
#  router1とrouter2を介してつながっている。
#  pingコマンドでns1からns2へのネットワークの疎通を確認する。
#  ns1とns2にはデフォルトゲートウェイとしてルーターのIPアドレスを設定する。
#  ネットワークへのルーティングテーブルは以下の通りである。
#
# ns1 ルーティングテーブル
# +--------------+-----------------+----------------
# | 宛先アドレス | サブネットマスク| ネクストホップ
# +--------------+-----------------+----------------
# | default      | 255.255.255.0   | 192.0.2.254 
# | 192.0.2.0    | 255.255.255.0   | 192.0.2.1
# +--------------+-----------------+----------------
# 
# router1 ルーティングテーブル
# +--------------+-----------------+----------------
# | 宛先アドレス | サブネットマスク| ネクストホップ
# +--------------+-----------------+----------------
# | default      | 255.255.255.0   | 198.51.100.2 
# | 192.0.2.0    | 255.255.255.0   | 192.0.2.254
# | 198.51.100.0 | 255.255.255.0   | 198.51.100.1
# +--------------+-----------------+----------------
#
# router2 ルーティングテーブル
# +--------------+-----------------+----------------
# | 宛先アドレス | サブネットマスク| ネクストホップ
# +--------------+-----------------+----------------
# | default      | 255.255.255.0   | 198.51.100.1
# | 198.51.100.0 | 255.255.255.0   | 198.51.100.2
# | 203.0.113.0  | 255.255.255.0   | 203.0.113.254
# +--------------+-----------------+----------------
#
# ns2 ルーティングテーブル
# +--------------+-----------------+----------------
# | 宛先アドレス | サブネットマスク| ネクストホップ
# +--------------+-----------------+----------------
# | default      | 255.255.255.0   | 203.0.113.254 
# | 203.0.113.0  | 255.255.255.0   | 203.0.113.1
# +--------------+-----------------+----------------
#

#
# 注意：traceroute コマンドはインストールされていないので、次のコマンドを実行する
#  $ apt install traceroute
#

#状態(status): 
# 0:初期状態
# 1:ネットワークネームスペースns1,router1,router2,ns2を作成した状態
# 2:仮想ネットワークインタフェースns1-veth0,gw1-veth0,gw1-veth1,gw2-veth0,gw2-veth1,ns2-veth0を作成した状態
# 3:仮想ネットワークインタフェースをns1,router1,router2,ns2に配置した状態
# 4:仮想ネットワークインタフェースにIPアドレスを設定した状態
# 5:仮想ネットワークインタフェースを有効にした状態
# 6:仮想ネットワークインタフェースにデフォルトゲートウェイを設定した状態
# 7:Linuxカーネルの設定でルーターの機能を有効にした状態
if [  -e ./.namespace_tmp ]
then
	stat=$(cat ./.namespace_tmp)
else
	stat=0    
fi

function fn_fig1() {
cat << END
#
#  ns1
# +--------------+     
# |              |     
# |              |  
# |              |    
# |              |    
# +--------------+     
#                        router1
#                       +-----------------+    
#                       |                 |    
#                       |                 |    
#                       |                 |    
#                       |                 |    
#                       +-----------------+    
#                                              
#                                                  router2
#                                                 +----------------+    
#                                                 |                |    
#                                                 |                |    
#                                                 |                |    
#                                                 |                |    
#                                                 +----------------+    
#                                                                       
#                                                                           ns2
#                                                                          +------------------+ 
#                                                                          |                  |
#                                                                          |                  |
#                                                                          |                  |
#                                                                          |                  |
#                                                                          +------------------+
#

END
}

function fn_exp1() {
cat << END
# E03-1) Network Namespace として ns1,router1,router2,ns2 を作成する

# ネットワークネームスペースを4つ作成します。ns1とrouter1とrouter2とns2です。
# これらはホストOSのLinuxからはネットワーク的に独立しています。ここではns1と
# router1とrouter2とns2を仮想PCとして扱います。
# 
# sudo ip netns add ns1
# sudo ip netns add router1
# sudo ip netns add router2
# sudo ip netns add ns2
#
#「sudo 管理者コマンド」は、管理者権限が無いと実行できないコマンドを特別に許可さ
# れたユーザーが実行できるようにするためのコマンドです。ipコマンドの一部の機能を
# 実行するには管理者権限が必要です。
#
#「ip netns」コマンドはネットワークネームスペース関連の設定をするコマンドです。
#「ip netns add ネットワークネームスペース名」は、ネットワークネームスペースを
# 作成します。作成したネットワークネームスペースは「ip netns list」コマンドで
# 確認できます(メニュー 6.ネットワークネームスペースを確認)。

END
}

function fn_fig2() {
cat << END
#
#  ns1             
# +--------------+    
# |              | ns1-veth0 
# |              |   o 
# |              |   |
# |              |   |
# +--------------+   | 
#                    |   router1           
#                    |  +-----------------+    
#                    o  |                 |    
#             gw1-veth0 |                 | 
#                       |                 | gw1-veth1 
#                       |                 |   o
#                       +-----------------+   |
#                                             |
#                                             |    router2  
#                                             |   +----------------+    
#                                             o   |                |    
#                                       gw2-veth0 |                | 
#                                                 |                | gw2-veth1 
#                                                 |                |   o
#                                                 +----------------+   |
#                                                                      |
#                                                                      |    ns2
#                                                                      |   +------------------+ 
#                                                                      o   |                  |
#                                                                ns2-veth0 |                  |
#                                                                          |                  |
#                                                                          |                  |
#                                                                          +------------------+
#

END
}

function fn_exp2() {
cat << END
# 6個の仮想ネットワークインタフェース(NIC)を作成します。接続するネットワーク
# ケーブルの組み合わせは次の通りです。
# ns1-veth0 <---> gw1-veth0 
# gw1-veth1 <---> gw2-veth0
# gw2-veth1 <---> ns2-veth0 
# ここでは仮想ネットワークインタフェースはまだネットワークネームスペースに
# 配置されていません。
#
# sudo ip link add ns1-veth0 type veth peer name gw1-veth0
# sudo ip link add gw1-veth1 type veth peer name gw2-veth0
# sudo ip link add gw2-veth1 type veth peer name ns2-veth0
#
# 「ip link」コマンドは、ネットワークインタフェース関連の設定をするコマンドです。
#   add NIC名       :仮想ネットワークインタフェース名を追加します。
#   type タイプ     :タイプのvethは仮想イーサネット(virtual ethernet)を指定します。
#   peer name NIC名 :ペアとなる仮想ネットワークインタフェース名を指定します。

END
}

function fn_fig3() {
cat << END
#
#  ns1             
# +--------------+ 
# |     DOWN     |  
# |   ns1-veth0  o---+ 
# |              |   |
# +--------------+   | 
#                    |   router1  
#                    |  +-----------------+    
#                    |  |   DOWN          |    
#                    +--o gw1-veth0       |    
#                       |                 |    
#                       |         DOWN    |    
#                       |       gw1-veth1 o---+
#                       |                 |   |
#                       +-----------------+   |
#                                             |
#                                             |    router2       
#                                             |   +----------------+    
#                                             |   |   DOWN         |    
#                                             +---o gw2-veth0      |    
#                                                 |                |    
#                                                 |        DOWN    |    
#                                                 |      gw2-veth1 o---+
#                                                 |                |   |
#                                                 +----------------+   |
#                                                                      |
#                                                                      |    ns2
#                                                                      |   +------------------+ 
#                                                                      |   |   DOWN           |
#                                                                      +---o ns2-veth0        |
#                                                                          |                  |
#                                                                          +------------------+
#

END
}

function fn_exp3() {
cat << END
# 仮想ネットワークインタフェースをネットワークネームスペースに配置します。
# sudo ip link set ns1-veth0 netns ns1
# sudo ip link set gw1-veth0 netns router1
# sudo ip link set gw1-veth1 netns router1
# sudo ip link set gw2-veth0 netns router2
# sudo ip link set gw2-veth1 netns router2
# sudo ip link set ns2-veth0 netns ns2
#
# これで仮想ネットワーク上においてns1,router1,router2,ns2がケーブルで接続されました。
# しかし、まだ仮想ネットワークインタフェースは無効(DOWN)な状態です。
# よってまだ通信はできません。
#
# 「ip link set 仮想NIC名 netns ネットワークネームスペース名 」コマンドは、
# は仮想ネットワークインタフェースをネットワークネームスペースに配置します。 

END
}

function fn_fig4() {
cat << END
#
#  ns1             [192.0.2.0/24]
# +--------------+   | 
# |     DOWN     |   | 
# |   ns1-veth0  o---+ 
# | 192.0.2.1/24 |   | 
# |              |   |
# +--------------+   | 
#                    |   router1            [198.51.100.0/24]
#                    |  +-----------------+   |
#                    |  |   DOWN          |   |
#                    +--o gw1-veth0       |   |
#                    |  | 192.0.2.254/24  |   |
#                    |  |                 |   |
#                    |  |         DOWN    |   |
#                    |  |       gw1-veth1 o---+
#                    |  | 198.51.100.1/24 |   |
#                    |  +-----------------+   |
#                                             |
#                                             |    router2           [203.0.113.0/24]
#                                             |   +------------------+   |
#                                             |   |    DOWN          |   |
#                                             +---o gw2-veth0        |   |
#                                             |   | 198.51.100.2/24  |   |
#                                             |   |                  |   |
#                                             |   |           DOWN   |   |
#                                             |   |        gw2-veth1 o---+
#                                             |   | 203.0.113.254/24 |   |
#                                             |   +------------------+   |
#                                                                        |
#                                                                        |    ns2
#                                                                        |   +------------------+ 
#                                                                        |   |    DOWN          |
#                                                                        +---o ns2-veth0        |
#                                                                        |   | 203.0.113.1/24   |
#                                                                        |   |                  |
#                                                                        |   +------------------+
#

END
}

function fn_exp4() {
cat << END
# 6つの仮想ネットワークインタフェースにIPアドレスを設定する。
#
# sudo ip netns exec ns1     ip address add 192.0.2.1/24     dev ns1-veth0 
# sudo ip netns exec router1 ip address add 192.0.2.254/24   dev gw1-veth0 
# sudo ip netns exec router1 ip address add 198.51.100.1/24  dev gw1-veth1
# sudo ip netns exec router2 ip address add 198.51.100.2/24  dev gw2-veth0 
# sudo ip netns exec router2 ip address add 203.0.113.254/24 dev gw2-veth1
# sudo ip netns exec ns2     ip address add 203.0.113.1/24   dev ns2-veth0 
#
# 「ip netns exec」コマンドはネットワークネームスペース内でコマンドを実行する
# ためのコマンドです。ns1とns2はネットワーク的に独立しているために、ns1内に
# あるns1-veth0にIPアドレスを設定するためには、ns1の内部で ip addressコマンド
# を実行する必要があります。
# 「ip address」コマンドはIPアドレスを表示したり、IPアドレスを設定したりします。
# 「ip address add IPアドレス dev ネットワークインタフェース」は、IPアドレスを
# ネットワークインタフェースに設定します。 
# まだ仮想ネットワークインタフェースは無効(DOWN)な状態です。
# 

END
}

function fn_fig5() {
cat << END
#
#  ns1             [192.0.2.0/24]
# +--------------+   | 
# |      UP      |   | 
# |   ns1-veth0  O---+ 
# | 192.0.2.1/24 |   | 
# |              |   |
# +--------------+   | 
#                    |   router1            [198.51.100.0/24]
#                    |  +-----------------+   |
#                    |  |    UP           |   |
#                    +--O gw1-veth0       |   |
#                    |  | 192.0.2.254/24  |   |
#                    |  |                 |   |
#                    |  |          UP     |   |
#                    |  |       gw1-veth1 O---+
#                    |  | 198.51.100.1/24 |   |
#                    |  +-----------------+   |
#                                             |
#                                             |    router2           [203.0.113.0/24]
#                                             |   +------------------+   |
#                                             |   |    UP            |   |
#                                             +---O gw2-veth0        |   |
#                                             |   | 198.51.100.2/24  |   |
#                                             |   |                  |   |
#                                             |   |           UP     |   |
#                                             |   |        gw2-veth1 O---+
#                                             |   | 203.0.113.254/24 |   |
#                                             |   +------------------+   |
#                                                                        |
#                                                                        |    ns2
#                                                                        |   +------------------+ 
#                                                                        |   |    UP            |
#                                                                        +---O ns2-veth0        |
#                                                                        |   | 203.0.113.1/24   |
#                                                                        |   |                  |
#                                                                        |   +------------------+
#

END
}

function fn_exp5() {
cat << END
# 仮想ネットワークインタフェースを有効化(UP)します。
#
# sudo ip netns exec ns1     ip link set ns1-veth0 up
# sudo ip netns exec router1 ip link set gw1-veth0 up
# sudo ip netns exec router1 ip link set gw1-veth1 up
# sudo ip netns exec router2 ip link set gw2-veth0 up
# sudo ip netns exec router2 ip link set gw2-veth1 up
# sudo ip netns exec ns2     ip link set ns2-veth0 up
#
# 「ip link set <device> up」コマンドはネットワークインタフェースを有効化 
# (UP)します。
#

END
}

function fn_fig6() {
cat << END
#
#  ns1             [192.0.2.0/24]
# +--------------+   | 
# |      UP      |   | 
# |    ns1-veth0 O---+ 
# | 192.0.2.1/24 |   | 
# |              |   |
# |GW 192.0.2.254|   | 
# +--------------+   | 
#                    |   router1            [198.51.100.0/24]
#                    |  +-----------------+   |
#                    |  |    UP           |   |
#                    +--O gw1-veth0       |   |
#                    |  | 192.0.2.254/24  |   |
#                    |  |                 |   |
#                    |  |          UP     |   |
#                    |  |       gw1-veth1 O---+
#                    |  | 198.51.100.1/24 |   |
#                    |  |                 |   |
#                    |  | GW 198.51.100.2 |   |
#                    |  +-----------------+   |
#                                             |
#                                             |    router2           [203.0.113.0/24]
#                                             |   +------------------+   |
#                                             |   |    UP            |   |
#                                             +---O gw2-veth0        |   |
#                                             |   | 198.51.100.2/24  |   |
#                                             |   |                  |   |
#                                             |   |         UP       |   |
#                                             |   |        gw2-veth1 O---+
#                                             |   | 203.0.113.254/24 |   |
#                                             |   |                  |   |
#                                             |   | GW 198.51.100.1  |   |
#                                             |   +------------------+   |
#                                                                        |
#                                                                        |    ns2
#                                                                        |   +------------------+ 
#                                                                        |   |    UP            |
#                                                                        +---O ns2-veth0        |
#                                                                        |   | 203.0.113.1/24   |
#                                                                        |   |                  |
#                                                                        |   | GW 203.0.113.254 |
#                                                                        |   +------------------+
#

END
}

function fn_exp6() {
cat << END
# ns1,ns2,router1,router2にデフォルトゲートウェイを設定する
#
# sudo ip netns exec ns1     ip route add default via 192.0.2.254
# sudo ip netns exec ns2     ip route add default via 203.0.113.254
# sudo ip netns exec router1 ip route add default via 198.51.100.2
# sudo ip netns exec router2 ip route add default via 198.51.100.1
#
# 「ip route add default via ipアドレス」コマンドはネットワークインタフェースに
# デフォルトゲートウェイを設定します。
#

END
}

function fn_fig7() {
cat << END
#
#  ns1             [192.0.2.0/24]
# +--------------+  | 
# |      UP      |  | 
# |   ns1-veth0  O--+ 
# | 192.0.2.1/24 |  | 
# |              |  |
# |GW 192.0.2.254|  | 
# +--------------+  | 
#                   |   router1               [198.51.100.0/24]
#                   |  +--------------------+  |
#                   |  |    UP              |  |
#                   +--O gw1-veth0          |  |
#                   |  | 192.0.2.254/24     |  |
#                   |  |                    |  |
#                   |  |             UP     |  |
#                   |  |          gw1-veth1 O--+
#                   |  |    198.51.100.1/24 |  |
#                   |  |                    |  |
#                   |  |  GW 198.51.100.2   |  |
#                   |  |                    |  | 
#                   |  |net.ipv4.ip_foward=1|  |
#                   |  +--------------------+  |
#                                              |
#                                              |    router2              [203.0.113.0/24]
#                                              |  +--------------------+  |
#                                              |  |    UP              |  |
#                                              +--O gw2-veth0          |  |
#                                              |  | 198.51.100.2/24    |  |
#                                              |  |                    |  |
#                                              |  |             UP     |  |
#                                              |  |          gw2-veth1 O--+
#                                              |  |   203.0.113.254/24 |  |
#                                              |  |                    |  |
#                                              |  |  GW 198.51.100.1   |  |
#                                              |  |                    |  |
#                                              |  |net.ipv4.ip_foward=1|  |
#                                              |  +--------------------+  |
#                                                                         |
#                                                                         |   ns2
#                                                                         |  +------------------+ 
#                                                                         |  |    UP            |
#                                                                         +--O ns2-veth0        |
#                                                                         |  | 203.0.113.1/24   |
#                                                                         |  |                  |
#                                                                         |  | GW 203.0.113.254 |
#                                                                         |  +------------------+

END
}

function fn_exp7() {
cat << END
# Linuxカーネルの設定でrouter1,router2のルーター機能を有効にする
#
# sudo ip netns exec router1 sysctl net.ipv4.ip_forward=1 > /dev/null
# sudo ip netns exec router2 sysctl net.ipv4.ip_forward=1 > /dev/null

END
}

function fn_fig() {
    echo ''
    case $stat in
        0) echo 'ネットワークネームスペースがありません' 
           ;;
        1) echo '状態(1)'
           fn_fig1 
           ;;
        2) echo '状態(2)'
           fn_fig2
           ;;
        3) echo '状態(3)'
           fn_fig3
           ;;
        4) echo '状態(4)'
           fn_fig4
           ;;
        5) echo '状態(5)'
           fn_fig5
           ;;
        6) echo '状態(6)'
           fn_fig6
           ;;
        7) echo '状態(7)'
           fn_fig7
           ;;
    esac
}

function fn_hitAnyKey(){
    echo "> hit any key!"
    read keyin
}

function fn_menu() {
echo '===メニュー===================================='
PS3='番号を入力>'

menu_list='
ネットワークネームスペースを作成
仮想ネットワークインタフェースを作成
仮想ネットワークインタフェースを配置
仮想ネットワークインタフェースにIPアドレスを設定
仮想ネットワークインタフェースを有効化
ネットワークネームスペースにデフォルトゲートウェイを設定
Linuxカーネルの設定でルーターの機能を有効化
ネットワークネームスペースを確認
仮想インタフェースを確認
ルーティングテーブルを確認
pingを実行
tracerouteを実行
状態を表示
ネットワークネームスペースをすべて削除
終了
課題提出用の出力'

select item in $menu_list
do
    echo ""
    echo "${REPLY}) ${item}します"
    case $REPLY in
    1) #ネットワークネームスペースを作成する
        echo sudo ip netns add ns1
        echo sudo ip netns add router1
        echo sudo ip netns add router2
        echo sudo ip netns add ns2
        echo ''
        sudo ip netns add ns1
        sudo ip netns add router1
        sudo ip netns add router2
        sudo ip netns add ns2
        stat=1
        echo $stat > ./.namespace_tmp
        fn_fig
        fn_exp1
        ;;
    2) #仮想ネットワークインタフェースを作成する
        echo sudo ip link add ns1-veth0 type veth peer name gw1-veth0
        echo sudo ip link add gw1-veth1 type veth peer name gw2-veth0
        echo sudo ip link add gw2-veth1 type veth peer name ns2-veth0
        echo ''
		sudo ip link add ns1-veth0 type veth peer name gw1-veth0
		sudo ip link add gw1-veth1 type veth peer name gw2-veth0
		sudo ip link add gw2-veth1 type veth peer name ns2-veth0
        stat=2
        echo $stat > ./.namespace_tmp
        fn_fig
        fn_exp2
        ;;
    3) #仮想ネットワークインタフェースを配置する
		echo sudo ip link set ns1-veth0 netns ns1
		echo sudo ip link set gw1-veth0 netns router1
		echo sudo ip link set gw1-veth1 netns router1
		echo sudo ip link set gw2-veth0 netns router2
		echo sudo ip link set gw2-veth1 netns router2
		echo sudo ip link set ns2-veth0 netns ns2
        echo ''
		sudo ip link set ns1-veth0 netns ns1
		sudo ip link set gw1-veth0 netns router1
		sudo ip link set gw1-veth1 netns router1
		sudo ip link set gw2-veth0 netns router2
		sudo ip link set gw2-veth1 netns router2
		sudo ip link set ns2-veth0 netns ns2
        stat=3
        echo $stat > ./.namespace_tmp
        fn_fig
        fn_exp3
        ;;
    4) #仮想ネットワークインタフェースにIPアドレスを設定する
		echo sudo ip netns exec ns1     ip address add 192.0.2.1/24     dev ns1-veth0 
		echo sudo ip netns exec router1 ip address add 192.0.2.254/24   dev gw1-veth0 
		echo sudo ip netns exec router1 ip address add 198.51.100.1/24  dev gw1-veth1
		echo sudo ip netns exec router2 ip address add 198.51.100.2/24  dev gw2-veth0 
		echo sudo ip netns exec router2 ip address add 203.0.113.254/24 dev gw2-veth1
		echo sudo ip netns exec ns2     ip address add 203.0.113.1/24   dev ns2-veth0 
        echo ''
		sudo ip netns exec ns1     ip address add 192.0.2.1/24     dev ns1-veth0 
		sudo ip netns exec router1 ip address add 192.0.2.254/24   dev gw1-veth0 
		sudo ip netns exec router1 ip address add 198.51.100.1/24  dev gw1-veth1
		sudo ip netns exec router2 ip address add 198.51.100.2/24  dev gw2-veth0 
		sudo ip netns exec router2 ip address add 203.0.113.254/24 dev gw2-veth1
		sudo ip netns exec ns2     ip address add 203.0.113.1/24   dev ns2-veth0 
        stat=4
        echo $stat > ./.namespace_tmp
        fn_fig
        fn_exp4
        ;;
    5) #仮想ネットワークインタフェースを有効にする
		echo sudo ip netns exec ns1     ip link set ns1-veth0 up
		echo sudo ip netns exec router1 ip link set gw1-veth0 up
		echo sudo ip netns exec router1 ip link set gw1-veth1 up
		echo sudo ip netns exec router2 ip link set gw2-veth0 up
		echo sudo ip netns exec router2 ip link set gw2-veth1 up
		echo sudo ip netns exec ns2     ip link set ns2-veth0 up
        echo ''
		sudo ip netns exec ns1     ip link set ns1-veth0 up
		sudo ip netns exec router1 ip link set gw1-veth0 up
		sudo ip netns exec router1 ip link set gw1-veth1 up
		sudo ip netns exec router2 ip link set gw2-veth0 up
		sudo ip netns exec router2 ip link set gw2-veth1 up
		sudo ip netns exec ns2     ip link set ns2-veth0 up
        stat=5
        echo $stat > ./.namespace_tmp
        fn_fig
        fn_exp5
        ;;
    6) #ns1,ns2,router1,router2にデフォルトゲートウェイを設定する
		echo sudo ip netns exec ns1     ip route add default via 192.0.2.254
		echo sudo ip netns exec ns2     ip route add default via 203.0.113.254
		echo sudo ip netns exec router1 ip route add default via 198.51.100.2
		echo sudo ip netns exec router2 ip route add default via 198.51.100.1
        echo ''
		sudo ip netns exec ns1     ip route add default via 192.0.2.254
		sudo ip netns exec ns2     ip route add default via 203.0.113.254
		sudo ip netns exec router1 ip route add default via 198.51.100.2
		sudo ip netns exec router2 ip route add default via 198.51.100.1
        stat=6
        echo $stat > ./.namespace_tmp
        fn_fig
        fn_exp6
        ;;
    7) #Linuxカーネルの設定でルーターの機能を有効にする
		echo sudo ip netns exec router1 sysctl net.ipv4.ip_forward=1 > /dev/null
		echo sudo ip netns exec router2 sysctl net.ipv4.ip_forward=1 > /dev/null
        echo ''
		sudo ip netns exec router1 sysctl net.ipv4.ip_forward=1 > /dev/null
		sudo ip netns exec router2 sysctl net.ipv4.ip_forward=1 > /dev/null
        stat=7
        echo $stat > ./.namespace_tmp
        fn_fig
        fn_exp7
        ;;
    8) #ネットワークネームスペースを確認する
        echo ip netns list
        echo ''
        ip netns list
        ;;
    9) #仮想ネットワークインタフェースを確認する
        echo '----------------------------------------------------'
        echo sudo ip netns exec ns1 ip link list
        echo ''
        sudo ip netns exec ns1 ip link list
        echo '----------------------------------------------------'
        echo sudo ip netns exec router1 ip link list
        echo ''
        sudo ip netns exec router1 ip link list
        echo '----------------------------------------------------'
        echo sudo ip netns exec router2 ip link list
        echo ''
        sudo ip netns exec router2 ip link list
        echo '----------------------------------------------------'
        echo sudo ip netns exec ns2 ip link list
        echo ''
        sudo ip netns exec ns2 ip link list
        echo '----------------------------------------------------'
        ;;
    10) #ns1,router1,router2,ns2のルーティングテーブルを確認する
        export TZ='Asia/Tokyo'
        echo '--------------------------------------------------------------------------------------'
        echo '# ns1のルーティングテーブルを表示する'
        echo sudo ip netns exec ns1 route -n
        echo ''
        sudo ip netns exec ns1 route -n
        echo ''
        echo '--------------------------------------------------------------------------------------'
        echo '# router1のルーティングテーブルを表示する'
        echo sudo ip netns exec router1 route -n
        echo ''
        sudo ip netns exec router1 route -n
        echo ''
        echo '--------------------------------------------------------------------------------------'
        echo '# router2のルーティングテーブルを表示する'
        echo sudo ip netns exec router2 route -n
        echo ''
        sudo ip netns exec router2 route -n
        echo ''
        echo '--------------------------------------------------------------------------------------'
        echo '# ns2のルーティングテーブルを表示する'
        echo sudo ip netns exec ns2 route -n
        echo ''
        sudo ip netns exec ns2 route -n
        echo ''
        echo '--------------------------------------------------------------------------------------'
        echo ''
        echo '# 0.0.0.0 というアドレスは文脈によって意味が異なる。'
        echo '# 受信先サイトの 0.0.0.0/0 はすべてのアドレスを表している。つまりデフォルト・ルートである。'
        echo '# デフォルト・ルートとはすべてのネットワークを集約した経路のことです。'
        echo '# ゲートウェイの 0.0.0.0/24 はNICの自分自身のアドレスを表している。'
        ;; 
    11) #pingを実行(ns1->ns2)する
        echo '----------------------------------------------------'
        echo 'ns1 から ns2 へpingを実行'
        #echo sudo ip netns exec ns1 ping -c 5 -I 192.0.2.1 203.0.113.1
        echo  sudo ip netns exec ns1 ping -c 5 -I ns1-veth0 203.0.113.1
        echo ''
        sudo ip netns exec ns1 ping -c 5 -I ns1-veth0 203.0.113.1
        sleep 2

        #pingを実行(ns2->ns1)する
        echo ''
        echo '----------------------------------------------------'
        echo 'ns2 から ns1 へpingを実行'
        echo sudo ip netns exec ns2 ping -c 5 -I ns2-veth0 192.0.2.1
        echo ''
        sudo ip netns exec ns2 ping -c 5 -I ns2-veth0 192.0.2.1
        echo '----------------------------------------------------'
        ;;
    12) #tracerouteを実行
        echo '----------------------------------------------------'
        echo 'ns1 から ns2 へtracerouteを実行'
        sudo ip netns exec ns1 traceroute -N 1 -q 1 203.0.113.1
        ;;
    13) #状態を表示する
        if [  -e ./.namespace_tmp ]
        then
            stat=$(cat ./.namespace_tmp)
        else
            stat=0
        fi
        fn_fig
        ;;
    14) #ネットワークネームスペースをすべて削除する
        echo sudo ip -all netns delete
        echo ''
        sudo ip -all netns delete
        stat=0
        rm ./.namespace_tmp
        ;;
    15) #終了する
        echo "bye bye!"
        exit
        ;;
    16) #課題提出用の出力
        if [ $stat = 7 ]
        then
			echo ''
			echo '----ここから----'
			read -p '学生番号> ' unumber
			read -p '氏  名  > ' uname
			echo    'ID      >' $(echo $unumber | md5sum)
			echo ''
			date
			fn_fig        

			echo '--------------------------------------------------------------------------------------'
			echo '# ns1のルーティングテーブル'
			echo ''
			sudo ip netns exec ns1 route -n
			echo ''
			echo '--------------------------------------------------------------------------------------'
			echo '# router1のルーティングテーブルを表示する'
			sudo ip netns exec router1 route -n
			echo ''
			echo '--------------------------------------------------------------------------------------'
			echo '# router2のルーティングテーブルを表示する'
			echo ''
			sudo ip netns exec router2 route -n
			echo ''
			echo '--------------------------------------------------------------------------------------'
			echo '# ns2のルーティングテーブルを表示する'
			echo ''
			sudo ip netns exec ns2 route -n
			echo ''
			echo '--------------------------------------------------------------------------------------'

			#pingを実行(ns1->ns2)する
			echo ''
			echo 'ns1 から ns2 へpingを実行'
			echo ''
			sudo ip netns exec ns1 ping -c 5 -I ns1-veth0 203.0.113.1

			#pingを実行(ns2->ns1)する
			echo ''
			echo 'ns2 から ns1 へpingを実行'
			echo ''
			sudo ip netns exec ns2 ping -c 5 -I ns2-veth0 192.0.2.1

			#ns1からns2へtracerouteを実行
			echo ''
			echo '----------------------------------------------------'
			echo ''
			echo 'ns1 から ns2 へtracerouteを実行'
			sudo ip netns exec ns1 traceroute -N 1 -q 1 203.0.113.1
			echo ''
			echo '----ここまで----'
			echo ''
        else
			echo ''
			echo 'エラー：課題を出力できません。'
			echo ''
        fi
        ;;
    *)
        echo "番号を入力してください"
    esac

    echo ""
    echo "Enterキーを押してください。"
    read n

    #sleep 2
    fn_menu
done

}

#### START BASH SCRIPT #########################################################

echo '###'
echo '### Network Name Spaceを使った仮想ネットワークの作成'
echo '###'

echo ''
echo 'これから作成するネットワーク'
fn_fig7
sleep 3

echo ""
echo "Enterキーを押してください。"
read n

fn_menu
fn_hitAnyKey


# ドキュメント用IPアドレス
# 文書用のIPv4のアドレスとして予約されているのが次のアドレスである。
# 実在するIPアドレスを使用すると迷惑が掛かる場合は、ドキュメント用のIPアドレスを使用する
# 192.0.2.0/24
# 198.51.100.0/24
# 203.0.113.0/24

# vim: number tabstop=4 softtabstop=4 shiftwidth=4 textwidth=0 filetype=text:
