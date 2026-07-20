# Block incoming ICMP Timestamp Requests (Type 13)
New-NetFirewallRule -DisplayName "Block ICMP Timestamp Requests" `
 -Protocol ICMPv4 -IcmpType 13 -Direction Inbound -Action Block

# Block outgoing ICMP Timestamp Replies (Type 14)
New-NetFirewallRule -DisplayName "Block ICMP Timestamp Replies" `
 -Protocol ICMPv4 -IcmpType 14 -Direction Outbound -Action Block