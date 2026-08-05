import 'package:flutter/material.dart';

class EventType {
  final int? id;
  final String name;
  final int color;
  final String icon;

  EventType({this.id, required this.name, required this.color, this.icon = 'event'});

  IconData get iconData {
    switch (icon) {
      case 'restaurant': return Icons.restaurant;
      case 'cake': return Icons.cake;
      case 'coffee': return Icons.coffee;
      case 'local_dining': return Icons.local_dining;
      case 'breakfast_dining': return Icons.breakfast_dining;
      case 'lunch_dining': return Icons.lunch_dining;
      case 'dinner_dining': return Icons.dinner_dining;
      case 'bakery_dining': return Icons.bakery_dining;
      case 'ramen_dining': return Icons.ramen_dining;
      case 'tapas': return Icons.tapas;
      case 'kitchen': return Icons.kitchen;
      case 'egg': return Icons.egg;
      case 'set_meal': return Icons.set_meal;
      case 'fastfood': return Icons.fastfood;
      case 'local_pizza': return Icons.local_pizza;
      case 'local_bar': return Icons.local_bar;
      case 'wine_bar': return Icons.wine_bar;
      case 'celebration': return Icons.celebration;
      case 'menu_book': return Icons.menu_book;
      case 'menu': return Icons.menu;
      case 'bookmark': return Icons.bookmark;
      case 'event': return Icons.event;
      case 'schedule': return Icons.schedule;
      case 'star': return Icons.star;
      case 'workspaces': return Icons.workspaces;
      case 'group': return Icons.group;
      case 'school': return Icons.school;
      case 'book': return Icons.book;
      case 'assignment': return Icons.assignment;
      case 'science': return Icons.science;
      case 'favorite': return Icons.favorite;
      case 'check_circle': return Icons.check_circle;
      case 'alarm': return Icons.alarm;
      case 'notifications': return Icons.notifications;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'description': return Icons.description;
      case 'edit_note': return Icons.edit_note;
      case 'auto_stories': return Icons.auto_stories;
      case 'pan_tool': return Icons.pan_tool;
      case 'handyman': return Icons.handyman;
      case 'cleaning_services': return Icons.cleaning_services;
      default: return Icons.event;
    }
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) || (other is EventType && runtimeType == other.runtimeType && id != null && id == other.id);

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'color': color,
    'icon': icon,
  };

  factory EventType.fromMap(Map<String, dynamic> map) => EventType(
    id: map['id'] as int?,
    name: map['name'] as String,
    color: map['color'] as int,
    icon: map['icon'] as String? ?? 'event',
  );
}
