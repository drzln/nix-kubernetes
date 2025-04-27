# frozen_string_literal: true

template(:network) do
  product       = :kubernetes
  base_tags     = { product: product }
  base_cidr     = '10.2'
  ami           = 'ami-08ee7b48673f8a214'
  instance_type = 't3.micro'

  resource :aws_vpc, product do
    cidr_block "#{base_cidr}.0.0/16"
    enable_dns_support true
    enable_dns_hostnames true
    tags base_tags.merge(
      Name: "#{product}_vpc"
    )
  end

  vpc_id_ref = "${aws_vpc.#{product}.id}"

  resource :aws_internet_gateway, "#{product}_igw" do
    vpc_id vpc_id_ref
    tags base_tags.merge(Name: "#{product}_igw")
  end

  resource :aws_subnet, "#{product}_public_subnet" do
    vpc_id vpc_id_ref
    cidr_block "#{base_cidr}.1.0/24"
    map_public_ip_on_launch true
    availability_zone 'us-east-1a'
    tags base_tags.merge(Name: "#{product}_public_subnet")
  end

  resource :aws_security_group, "#{product}_sg" do
    vpc_id vpc_id_ref
    description 'Security group for kubernetes testing'
    tags base_tags.merge(Name: "#{product}_sg")
  end
  sg_ref = "${aws_security_group.#{product}_sg.id}"

  # Security Group Rules - Separate Resources

  ## Load Balancer: Allow HTTP/HTTPS from the internet
  # resource :aws_security_group_rule, "#{product}_lb_http_ingress" do
  #   security_group_id lb_sg_ref
  #   type 'ingress'
  #   from_port 80
  #   to_port 80
  #   protocol 'tcp'
  #   cidr_blocks ['0.0.0.0/0']
  # end

  # resource :aws_security_group_rule, "#{product}_lb_https_ingress" do
  #   security_group_id lb_sg_ref
  #   type 'ingress'
  #   from_port 443
  #   to_port 443
  #   protocol 'tcp'
  #   cidr_blocks ['0.0.0.0/0']
  # end

  ## Load Balancer Egress: Allow traffic to Web Tier
  # resource :aws_security_group_rule, "#{product}_lb_to_web_egress" do
  #   security_group_id lb_sg_ref
  #   type 'egress'
  #   from_port 80
  #   to_port 80
  #   protocol 'tcp'
  #   source_security_group_id web_sg_ref
  # end

  ## Web Tier: Allow traffic from Load Balancer only
  # resource :aws_security_group_rule, "#{product}_web_ingress_from_lb" do
  #   security_group_id web_sg_ref
  #   type 'ingress'
  #   from_port 80
  #   to_port 80
  #   protocol 'tcp'
  #   source_security_group_id lb_sg_ref
  # end

  ## Web Tier Egress: Allow traffic to Database Tier
  # resource :aws_security_group_rule, "#{product}_web_to_db_egress" do
  #   security_group_id web_sg_ref
  #   type 'egress'
  #   from_port 3306
  #   to_port 3306
  #   protocol 'tcp'
  #   source_security_group_id db_sg_ref
  # end

  ## Database Tier: Allow traffic from Web Tier only
  # resource :aws_security_group_rule, "#{product}_db_ingress_from_web" do
  #   security_group_id db_sg_ref
  #   type 'ingress'
  #   from_port 3306
  #   to_port 3306
  #   protocol 'tcp'
  #   source_security_group_id web_sg_ref
  # end

  #######################################################################################
  # compute testing
  #######################################################################################

  resource :aws_key_pair, "#{product}_key" do
    key_name product
    public_key File.read("#{Dir.home}/.ssh/id_rsa.pub") # Path to your local public key
    tags base_tags.merge(Name: product)
  end

  key_name_ref = "${aws_key_pair.#{product}_key.key_name}"
  resource :aws_launch_template, product do
    name "#{product}-nixos-template"
    image_id ami
    instance_type instance_type
    key_name key_name_ref
    vpc_security_group_ids [sg_ref]

    # NixOS Cloud Init (Replace this with a valid NixOS config)
    # user_data = Base64.strict_encode64(<<-EOF
    #   #cloud-config
    #   users:
    #     - name: admin
    #       sudo: ALL=(ALL) NOPASSWD:ALL
    #       shell: /bin/bash
    #       ssh_authorized_keys:
    #         - "your-public-ssh-key" # ⚠️ Add your SSH key
    #   EOF
    # )

    tag_specifications [{
      resource_type: 'instance',
      tags: base_tags.merge(Name: product)
    }]
  end

  launch_template_ref = "${aws_launch_template.#{product}.id}"
  web_subnet_ref      = "${aws_subnet.#{product}_public_subnet.id}"

  resource :aws_autoscaling_group, "#{product}_master_1" do
    launch_template(
      {
        id: launch_template_ref,
        version: '$Latest'
      }
    )
    desired_capacity 0
    max_size  0
    min_size  0
    vpc_zone_identifier [web_subnet_ref]
    tag [{
      key: 'Name',
      value: product,
      propagate_at_launch: true
    }]
  end
  resource :aws_autoscaling_group, "#{product}_master_2" do
    launch_template(
      {
        id: launch_template_ref,
        version: '$Latest'
      }
    )
    desired_capacity 0
    max_size  0
    min_size  0
    vpc_zone_identifier [web_subnet_ref]
    tag [{
      key: 'Name',
      value: product,
      propagate_at_launch: true
    }]
  end
  resource :aws_autoscaling_group, "#{product}_worker_1" do
    launch_template(
      {
        id: launch_template_ref,
        version: '$Latest'
      }
    )
    desired_capacity 0
    max_size  0
    min_size  0
    vpc_zone_identifier [web_subnet_ref]
    tag [{
      key: :Name,
      value: product,
      propagate_at_launch: true
    }]
  end
  resource :aws_autoscaling_group, "#{product}_worker_2" do
    launch_template(
      {
        id: launch_template_ref,
        version: :$Latest
      }
    )
    desired_capacity 0
    max_size  0
    min_size  0
    vpc_zone_identifier [web_subnet_ref]
    tag [{
      key: :Name,
      value: product,
      propagate_at_launch: true
    }]
  end
end
