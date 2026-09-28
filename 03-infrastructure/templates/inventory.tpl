all:
  children:
    k8s_cluster:
      children:
        masters:
          hosts:
            k8s-master:
              ansible_host: "${master_public_ip}"
              private_ip: "${master_internal_ip}"
              ansible_user: debian
        workers:
          hosts:
%{ for worker in workers ~}
            ${worker.name}:
              ansible_host: "${worker.internal_ip}"
              private_ip: "${worker.internal_ip}"
              ansible_user: debian
              ansible_ssh_common_args: '-o ProxyJump=debian@${master_public_ip}'
%{ endfor ~}
  vars:
    control_plane_endpoint: "${control_plane_endpoint}"
