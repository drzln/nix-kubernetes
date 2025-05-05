# frozen_string_literal: true
# infra/templates/network.rb

template(:network) do
  product       = :kubernetes
  base_tags     = { product: product }
  base_cidr     = '10.2'
  ami           = 'ami-08ee7b48673f8a214'
  instance_type = 'c5.xlarge'

  resource :aws_vpc, product do
    cidr_block           "#{base_cidr}.0.0/16"
    enable_dns_support   true
    enable_dns_hostnames true
    tags                 base_tags.merge(Name: "#{product}_vpc")
  end
  vpc_id_ref = "${aws_vpc.#{product}.id}"

  resource :aws_internet_gateway, "#{product}_igw" do
    vpc_id vpc_id_ref
    tags   base_tags.merge(Name: "#{product}_igw")
  end
  igw_id_ref = "${aws_internet_gateway.#{product}_igw.id}"

  resource :aws_subnet, "#{product}_public_subnet" do
    vpc_id                 vpc_id_ref
    cidr_block             "#{base_cidr}.1.0/24"
    map_public_ip_on_launch true
    availability_zone      'us-east-1a'
    tags                   base_tags.merge(Name: "#{product}_public_subnet")
  end
  public_subnet_ref = "${aws_subnet.#{product}_public_subnet.id}"

  resource :aws_route_table, "#{product}_public_rt" do
    vpc_id vpc_id_ref
    tags   base_tags.merge(Name: "#{product}_public_rt")
  end
  route_table_ref = "${aws_route_table.#{product}_public_rt.id}"

  resource :aws_route, "#{product}_igw_default_route" do
    route_table_id         route_table_ref
    destination_cidr_block '0.0.0.0/0'
    gateway_id             igw_id_ref
  end

  resource :aws_route_table_association, "#{product}_public_rt_assoc" do
    subnet_id      public_subnet_ref
    route_table_id route_table_ref
  end

  resource :aws_security_group, "#{product}_sg" do
    vpc_id      vpc_id_ref
    description 'Security group for Kubernetes test cluster'
    tags        base_tags.merge(Name: "#{product}_sg")
  end
  sg_ref = "${aws_security_group.#{product}_sg.id}"

  resource :aws_security_group_rule, "#{product}_sg_ssh_ingress" do
    security_group_id sg_ref
    type              :ingress
    from_port         22
    to_port           22
    protocol          :tcp
    cidr_blocks       ['0.0.0.0/0']
  end

  resource :aws_security_group_rule, "#{product}_sg_all_egress" do
    security_group_id sg_ref
    type              :egress
    from_port         0
    to_port           0
    protocol          '-1' # -1 = all protocols
    cidr_blocks       ['0.0.0.0/0']
  end

  resource :aws_key_pair, "#{product}_key" do
    key_name   product
    public_key File.read("#{Dir.home}/.ssh/id_rsa.pub")
    tags       base_tags.merge(Name: product)
  end
  key_name_ref = "${aws_key_pair.#{product}_key.key_name}"

  resource :aws_launch_template, product do
    name               "#{product}-nixos-template"
    image_id           ami
    instance_type      instance_type
    key_name           key_name_ref
    vpc_security_group_ids [sg_ref]

    tag_specifications [{
      resource_type: 'instance',
      tags: base_tags.merge(Name: product)
    }]
  end
  launch_template_ref = "${aws_launch_template.#{product}.id}"

  %w[master_1 master_2 worker_1 worker_2].each do |role|
    resource :aws_autoscaling_group, "#{product}_#{role}" do
      name "#{product}_#{role}"
      launch_template(
        id: launch_template_ref,
        version: '$Latest'
      )
      desired_capacity 0
      max_size         0
      min_size         0
      vpc_zone_identifier [public_subnet_ref]
      tag [
        { key: :colmena, value: role.tr('_', '-'), propagate_at_launch: true },
        { key: :Name,    value: product,           propagate_at_launch: true }
      ]
    end
  end
end
