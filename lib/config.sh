
trace () 
{
   echo "** $@"
   $@
}

read_ca_config ()
{
if [ -f "$ICI_CA_DIR/ca.config" ]; then
   . "$ICI_CA_DIR/ca.config"
fi
}

av_list ()
{
name=$1; shift
idx=1
if [ ! -z "$1" ]; then
   (
   IFS=,
   for v in $1; do
      if [ ! -z "$v" ]; then
         echo ${name}.$idx = "$v"
         idx=`expr $idx + 1`
      fi
   done 
   )
fi
}

c_init ()
{
cat<<EOC
openssl_conf = openssl_init
[openssl_init]
engines = engines_section
oid_section = oids

[oids]
domainComponent=0.9.2342.19200300.100.1.25

[engines_section]
pkcs11 = pkcs11_section

[pkcs11_section]
engine_id = pkcs11
dynamic_path = /usr/lib/engines/engine_pkcs11.so
MODULE_PATH = ${ICI_PKCS11}
PIN = ${ICI_PKCS11_PIN}
init = 0

EOC
}

c_req () 
{
cat<<EOC

[req]
default_bits           = ${ICI_BITS:=4096}
distinguished_name     = req_dn
prompt                 = no
x509_extensions        = extensions
default_md             = ${ICI_MD}
EOC
}

c_dn ()
{
echo
echo \# ${ICI_SUBJECT_DN}
echo "[req_dn]"
(
IFS=/
for rdn in ${ICI_SUBJECT_DN}; do
   if [ ! -z "$rdn" ]; then
      echo "$rdn" | awk -F= '{ print toupper($1) "=" $2 }'
   fi
done
)
}

c_ca ()
{
cat<<EOC
[ca]
default_ca = CA

[CA]
outdir                = "${ICI_CA_DIR}/certs"
certificate           = "${ICI_CA_DIR}/ca.crt"
default_md            = "${ICI_MD}"
serial                = "${ICI_CA_DIR}/serial"
database              = "${ICI_CA_DIR}/index.txt"
preserve              = no
unique_subject        = no
crl_extensions        = crl_extensions
EOC
if [ -f "${ICI_CA_DIR}/name.policy" ]; then
   echo "policy       = policy"
   echo
   cat "${ICI_CA_DIR}/name.policy"
fi
}

c_ext_common ()
{
cat<<EOC

[crl_extensions]

[extensions]
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid
EOC
}

c_ext_ca ()
{
cat<<EOC

basicConstraints        = critical,CA:TRUE
keyUsage                = critical,cRLSign, keyCertSign
EOC
}


c_ext_altnames ()
{
if [ ! -z "$ICI_ALTNAMES" ]; then
   echo "subjctAltNames = @altnames"

   echo "[altnames]"
   av_list 'email' "$ICI_EMAIL"
   av_list 'URI' "$ICI_URI"
   av_list 'DNS' "$ICI_DNS"
   av_list 'IP' "$ICI_IP"
fi
}

