# frozen_string_literal: true

# Define an environment to produce Packer AMIs
template(:packer) do
  product   = :packer
  base_tags = { product: product }
  cidr_base = '10.1'

  # VPC Definition
  resource :aws_vpc, product do
    cidr_block "#{cidr_base}.0.0/16"
    enable_dns_hostnames true
    enable_dns_support true
    tags base_tags.merge({ Name: "#{product}_vpc" })
  end

  vpc_id_ref = "${aws_vpc.#{product}.id}"

  # Internet Gateway
  resource :aws_internet_gateway, "#{product}_igw" do
    vpc_id vpc_id_ref
    tags base_tags.merge(Name: "#{product}_igw")
  end

  # Public Subnet
  resource :aws_subnet, "#{product}_public_packer" do
    vpc_id vpc_id_ref
    cidr_block "#{cidr_base}.1.0/24"
    map_public_ip_on_launch true
    availability_zone 'us-east-1a'
    tags base_tags.merge(Name: "#{product}_public_subnet")
  end

  subnet_id_ref = "${aws_subnet.#{product}_public_packer.id}"
  igw_id_ref = "${aws_internet_gateway.#{product}_igw.id}"

  # Route Table
  resource :aws_route_table, "#{product}_public_rt" do
    vpc_id vpc_id_ref
    tags base_tags.merge(Name: "#{product}_public_rt")
  end

  rt_id_ref = "${aws_route_table.#{product}_public_rt.id}"

  # Route for Internet Access
  resource :aws_route, "#{product}_default_route" do
    route_table_id rt_id_ref
    destination_cidr_block '0.0.0.0/0'
    gateway_id igw_id_ref
  end

  # Associate Route Table with Public Subnet
  resource :aws_route_table_association, "#{product}_public_assoc" do
    subnet_id subnet_id_ref
    route_table_id rt_id_ref
  end

  # Security Group for Packer
  # packer_sg_ref = "${aws_security_group.#{product}_packer.id}"
  # resource :aws_security_group, "#{product}_packer" do
  #   vpc_id vpc_id_ref
  #   tags base_tags.merge(Name: "#{product}_packer")
  # end

  # SSH Access Security Group Rule
  # resource :aws_security_group_rule, "#{product}_ssh_ingress" do
  #   security_group_id packer_sg_ref
  #   type 'ingress'
  #   from_port 22
  #   to_port 22
  #   protocol 'tcp'
  #   cidr_blocks ['0.0.0.0/0']
  # end
end
